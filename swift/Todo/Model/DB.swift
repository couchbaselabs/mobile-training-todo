//
// DB.swift
//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import CouchbaseLiteSwift

public enum DBError: Error {
    case notFound
    case invalidImage
}

public class DB {
    // Constants:
    public static let kActivities = ["Stopped", "Offline", "Connecting", "Idle", "Busy"]
    
    // Shared DB:
    public static let shared = DB()
    
    private var database: Database?
    private var replicator: Replicator?
    private var replicatorChangeListener: ListenerToken?
    private var pushNotificationReplicatorChangeListener: ListenerToken?
    
    private init() { }
    
    // MARK: Database
    
    public func open() throws {
        if database != nil {
            fatalError("Database is already opened")
        }
        
        // Open database:
        database = try Database(name: currentUser());
        
        // Create Indexes:
        try taskLists.createIndex(withName: "lists", config: ValueIndexConfiguration(["name"]))
        try tasks.createIndex(withName: "tasks", config: ValueIndexConfiguration(["taskList.id", "task"]))
    }
    
    public func close() throws {
        try openedDB().close()
        reset()
    }
    
    public func delete() throws {
        try openedDB().delete()
        reset()
    }
    
    private func createQuery(query: String) throws -> Query {
        return try openedDB().createQuery(query)
    }
    
    private func openedDB() -> Database {
        guard let db = database else {
            fatalError("No database opened")
        }
        return db
    }
    
    private func reset() {
        database = nil
        replicator = nil
        replicatorChangeListener = nil
        pushNotificationReplicatorChangeListener = nil
        
        _taskLists = nil
        _tasks = nil
        _users = nil
    }
    
    // MARK: User
    
    private func currentUser() -> String {
        if Session.shared.isLoggedIn {
            return Session.shared.username
        }
        fatalError("No current user")
    }
    
    // MARK: Collection
    
    private var _taskLists: Collection?
    private var _tasks: Collection?
    private var _users: Collection?
    
    private var taskLists: Collection {
        if (_taskLists == nil) {
            _taskLists = getCollection("lists")
        }
        return _taskLists!;
    }
    
    private var tasks: Collection {
        if (_tasks == nil) {
            _tasks = getCollection("tasks")
        }
        return _tasks!;
    }
    
    private var users: Collection {
        if (_users == nil) {
            _users = getCollection("users")
        }
        return _users!;
    }
    
    private func getCollection(_ name: String) -> Collection {
        return try! openedDB().createCollection(name: name)
    }
    
    // MARK: Replicator
    
    public func startReplicator(listener: @escaping (ReplicatorChange) -> Void) {
        guard !Config.shared.syncEnabled else {
            return
        }
        
        let config = replicatorConfiguration(continuous: true)
        replicator = Replicator(config: config)
        replicatorChangeListener = replicator!.addChangeListener({ (change) in
            let s = change.status
            let activity = DB.kActivities[Int(s.activity.rawValue)]
            let e = change.status.error as NSError?
            let error = e != nil ? ", error: \(e!.description)" : ""
            AppController.logger.log("[Todo] Replicator: \(activity), \(s.progress.completed)/\(s.progress.total)\(error)")
            listener(change)
        })
        replicator!.start()
    }
    
    public func startPushNotificationReplicator() {
        guard Config.shared.pushNotificationEnabled else { return }
        
        AppController.logger.log("[Todo] Start Background Replication ...")
        if database == nil {
            // Note : If the app is re-launched in the backgroud, there is no active user logged in.
            // We may implement auto-login in the future but right now this is not supported.
            AppController.logger.log("[Todo] Skipped Backgrund Replication as No Active Database Opened ...")
            return
        }
        
        let config = replicatorConfiguration(continuous: false)
        let repl = Replicator(config: config)
        pushNotificationReplicatorChangeListener = repl.addChangeListener({ (change) in
            let s = change.status
            let activity = DB.kActivities[Int(s.activity.rawValue)]
            let e = change.status.error as NSError?
            let error = e != nil ? ", error: \(e!.description)" : ""
            AppController.logger.log("[Todo] Push-Notification-Replicator: \(activity), \(s.progress.completed)/\(s.progress.total)\(error)")
            if let code = e?.code {
                if code == 401 {
                    AppController.logger.log("ERROR: Authentication Error, username or password is not correct");
                }
            }
        })
        repl.start()
    }
    
    private func replicatorConfiguration(continuous: Bool) -> ReplicatorConfiguration {
        let target = URLEndpoint(url: URL(string: Config.shared.syncURL)!)
        var config = ReplicatorConfiguration(target: target)
        config.continuous = continuous
        
        var auth: Authenticator? = nil
        if Session.shared.isLoggedIn {
            auth = BasicAuthenticator(username: Session.shared.username, password: Session.shared.password)
        } else {
            AppController.logger.log("[TODO] No user credentails found to setup the authenticator for replication")
        }
        config.authenticator = auth
        
        config.maxAttempts = Config.shared.maxAttempts
        config.maxAttemptWaitTime = Config.shared.maxAttemptWaitTime
        
        var conflictResolver: ConflictResolverProtocol?
        if Config.shared.ccrEnabled {
            conflictResolver = TestConflictResolver() { (conflict) -> Document? in
                switch Config.shared.ccrType {
                case .local:
                    return conflict.localDocument
                case .remote:
                    return conflict.remoteDocument
                case .delete:
                    return nil;
                }
            }
        }
        AppController.logger.log("[TODO] Custom Conflict Resolver: Enabled = \(Config.shared.ccrEnabled); Type = \(Config.shared.ccrType.description())")
        
        var collConfig = CollectionConfiguration()
        collConfig.conflictResolver = conflictResolver
        config.addCollections([taskLists, tasks, users], config: collConfig)
        
        return config
    }
    
    // MARK: Lists
    
    public func createTaskList(name: String) throws {
        let docID = currentUser() + "." + UUID().uuidString
        let doc = MutableDocument(id: docID)
        doc.setValue(name, forKey: "name")
        doc.setValue(currentUser(), forKey: "owner")
        try taskLists.save(document: doc);
    }
    
    public func updateTaskList(listID: String, name: String) throws {
        guard let doc = try taskLists.document(id: listID)?.toMutable() else {
            throw DBError.notFound
        }
        doc.setValue(name, forKey: "name")
        doc.setValue(currentUser(), forKey: "owner")
        try taskLists.save(document: doc);
    }
    
    public func deleteTaskList(listID: String) throws {
        if let doc = try taskLists.document(id: listID) {
            try taskLists.delete(document: doc)
        }
    }
    
    public func getTaskListByID(id: String) throws -> Document? {
        return try taskLists.document(id: id)
    }
    
    public func getTaskListsByName(name: String) throws -> ResultSet {
        let query = "SELECT meta().id, name FROM \(taskLists.name) WHERE name LIKE '%\(name)%' ORDER BY name"
        return try createQuery(query: query).execute()
    }
    
    public func getTaskListsQuery() throws -> Query {
        let query = "SELECT meta().id, name FROM \(taskLists.name) ORDER BY name"
        return try createQuery(query: query)
    }
    
    public func getIncompletedTasksCountsQuery() throws -> Query {
        let query = "SELECT taskList.id, count(1) FROM \(taskLists.name) WHERE complete == false GROUP BY taskList.id"
        return try createQuery(query: query)
    }
    
    // MARK: Tasks
    
    public func createTask(taskList: Document, task: String, extra: String? = nil) throws {
        let doc = MutableDocument()
        let owner = taskList.string(forKey: "owner")!
        let taskListInfo = ["id": taskList.id, "owner": owner]
        doc.setValue(taskListInfo, forKey: "taskList")
        doc.setValue(task, forKey: "task")
        doc.setValue(false, forKey: "complete")
        doc.setValue(Date(), forKey: "createdAt")
        if let ext = extra {
            doc.setValue(ext, forKey: "extra") // For testing with delta sync
        }
        try tasks.save(document: doc)
    }
    
    public func generateTasks(taskList: Document, numbers: Int, includesPhoto: Bool) throws {
        for i in 1...numbers {
            try autoreleasepool {
                let doc = MutableDocument()
                doc.setValue("task", forKey: "type")
                let taskListInfo = ["id": taskList.id, "owner": taskList.string(forKey: "owner")]
                doc.setValue(taskListInfo, forKey: "taskList")
                doc.setValue(Date(), forKey: "createdAt")
                doc.setValue("Task \(i)", forKey: "task")
                doc.setValue((i % 2) == 0, forKey: "complete")
                if (includesPhoto) {
                    let data = dataFromResource(name: "\(i % 10)", ofType: "JPG") as Data
                    let blob = Blob(contentType: "image/jpeg", data: data)
                    doc.setValue(blob, forKey: "image")
                }
                try tasks.save(document: doc)
            }
        }
    }
    
    public func updateTask(taskID: String, task: String) throws {
        guard let doc = try tasks.document(id: taskID)?.toMutable() else {
            throw DBError.notFound
        }
        doc.setValue(task, forKey: "task")
        try tasks.save(document: doc)
    }
    
    public func updateTask(taskID: String, complete: Bool) throws {
        guard let doc = try tasks.document(id: taskID)?.toMutable() else {
            throw DBError.notFound
        }
        doc.setValue(complete, forKey: "complete")
        try tasks.save(document: doc)
    }
    
    public func updateTask(taskID: String, image: UIImage?) throws {
        guard let doc = try tasks.document(id: taskID)?.toMutable() else {
            throw DBError.notFound
        }
        
        var blob: Blob? = nil
        if let image = image {
            guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
                throw DBError.invalidImage
            }
            blob = Blob(contentType: "image/jpeg", data: imageData)
        }
        doc.setValue(blob, forKey: "image")
        try tasks.save(document: doc)
    }
    
    public func deleteTask(taskID: String) throws {
        if let doc = try tasks.document(id: taskID) {
            try tasks.delete(document: doc)
        }
    }
    
    public func getTaskByID(id: String) throws -> Document? {
        return try tasks.document(id: id)
    }
    
    public func getTasksQuery(taskListID: String) throws -> Query {
        let query = "SELECT meta().id, task, complete, image FROM \(tasks.name) WHERE taskList.id == '\(taskListID)' ORDER BY createdAt, task"
        return try createQuery(query: query)
    }
    
    public func getTasks(taskListID: String) throws -> ResultSet {
        return try getTasksQuery(taskListID: taskListID).execute()
    }
    
    public func getTasksByTask(taskListID: String, task: String) throws -> ResultSet {
        let query = "SELECT meta().id, task, complete, image FROM \(tasks.name) WHERE taskList.id == '\(taskListID)' AND task LIKE '%\(task)%' ORDER BY createdAt, task"
        return try createQuery(query: query).execute()
    }
    
    // MARK: Users
    
    public func addSharedUser(taskList: Document, username: String) throws {
        let doc = MutableDocument(id: taskList.id + "." + username)
        doc.setValue(username, forKey: "username")
        
        let taskListInfo = MutableDictionaryObject()
        taskListInfo.setValue(taskList.id, forKey: "id")
        taskListInfo.setValue(taskList.string(forKey: "owner")!, forKey: "owner")
        doc.setValue(taskListInfo, forKey: "taskList")
        
        try users.save(document: doc)
    }
    
    public func deleteSharedUser(userID: String) throws {
        if let doc = try users.document(id: userID) {
            try users.delete(document: doc)
        }
    }
    
    public func getSharedUserByID(id: String) throws -> Document? {
        return try users.document(id: id)
    }
    
    public func getSharedUsersQuery(taskListID: String) throws -> Query {
        let query = "SELECT meta().id, username FROM \(users.name) WHERE taskList.id == '\(taskListID)' ORDER BY username"
        return try createQuery(query: query)
    }
    
    public func getSharedUsers(taskListID: String) throws -> ResultSet {
        let query = "SELECT meta().id, username FROM \(users.name) WHERE taskList.id == '\(taskListID)' ORDER BY username"
        return try createQuery(query: query).execute()
    }
    
    public func getSharedUsersByUsername(taskList: Document, username: String) throws -> ResultSet {
        let query = "SELECT meta().id, username FROM \(users.name) WHERE taskList.id == '\(taskList.id)' AND username LIKE '%\(username)%' ORDER BY username"
        return try createQuery(query: query).execute()
    }
    
    // MARK: Utils
    
    private func dataFromResource(name: String, ofType: String) -> NSData {
        let path = Bundle.main.path(forResource: name, ofType: ofType)
        return try! NSData(contentsOfFile: path!, options: [])
    }
}

class TestConflictResolver: ConflictResolverProtocol {
    let _resolver: (Conflict) -> Document?
    
    init(_ resolver: @escaping (Conflict) -> Document?) {
        _resolver = resolver
    }
    
    func resolve(conflict: Conflict) -> Document? {
        return _resolver(conflict)
    }
}
