//
// AppLogic-Swift.swift
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

import Foundation
import CouchbaseLiteSwift

public class AppLogicDelegate : AppLogicDelegateProtocol {
    let username: String
    let password: String
    
    private var db: Database!
    
    private var taskListsColl: Collection!
    private var tasksColl: Collection!
    private var usersColl: Collection!
    
    private var replicator: Replicator?
    private var replicatorChangeListener: ListenerToken?
    
    public required init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    public func open() throws {
        if db != nil {
            fatalError("Database is already open")
        }
        
        if Config.shared.loggingEnabled {
            Database.log.console.level = .info
        }
        
        // Open database:
        db = try Database(name: username);
        
        // Create or get collections:
        taskListsColl = try db.createCollection(name: "lists")
        tasksColl = try db.createCollection(name: "tasks")
        usersColl = try db.createCollection(name: "users")
        
        // Create Indexes:
        try taskListsColl.createIndex(withName: "lists", config: ValueIndexConfiguration(["name"]))
        try tasksColl.createIndex(withName: "tasks", config: ValueIndexConfiguration(["taskList.id", "task"]))
    }
    
    public func close() throws {
        try db.close()
    }
    
    public func delete() throws {
        try db.delete()
    }
    
    public func startReplicator() throws {
        let kActivities = ["Stopped", "Offline", "Connecting", "Idle", "Busy"]
        let config = replicatorConfiguration(continuous: true)
        replicator = Replicator(config: config)
        replicatorChangeListener = replicator!.addChangeListener({ (change) in
            let s = change.status
            let activity = kActivities[Int(s.activity.rawValue)]
            let e = change.status.error as NSError?
            let error = e != nil ? ", error: \(e!.description)" : ""
            AppController.logger.log("[Todo] Replicator: \(activity), \(s.progress.completed)/\(s.progress.total)\(error)")
        })
        replicator!.start()
    }
    
    public func createTaskList(name: String) async throws {
        let docID = username + "." + UUID().uuidString
        
        let role = "lists." + docID + ".contributor"
        try await SGAdmin.shared.createRole(role)
        
        let doc = MutableDocument(id: docID)
        doc.setValue(name, forKey: "name")
        doc.setValue(username, forKey: "owner")
        try taskListsColl.save(document: doc);
    }
    
    public func updateTaskList(_ taskList: TaskList) throws {
        guard let doc = try taskListsColl.document(id: taskList.id)?.toMutable() else {
            throw AppLogicError.notFound
        }
        doc.setValue(taskList.name, forKey: "name")
        try taskListsColl.save(document: doc);
    }
    
    public func deleteTaskList(_ taskList: TaskList) throws {
        if let doc = try taskListsColl.document(id: taskList.id) {
            try taskListsColl.delete(document: doc)
        }
    }
    
    public func getTaskListsQuery() throws -> LiveQueryObject {
        let query = "SELECT meta().id, name, owner FROM \(taskListsColl.name) ORDER BY name"
        return try LiveQuery.init(db.createQuery(query))
    }
    
    public func createTask(_ task: String, for taskList: TaskList) throws {
        let doc = MutableDocument()
        doc.setValue(["id": taskList.id, "owner": taskList.owner], forKey: "taskList")
        doc.setValue(task, forKey: "task")
        doc.setValue(false, forKey: "complete")
        doc.setValue(Date(), forKey: "createdAt")
        try tasksColl.save(document: doc)
    }
    
    public func createTask(_ task: Task) throws {
        let doc = MutableDocument()
        doc.setValue(["id": task.taskListID, "owner": task.owner], forKey: "taskList")
        doc.setValue(task.task, forKey: "task")
        doc.setValue(task.complete, forKey: "complete")
        doc.setValue(task.createdAt, forKey: "createdAt")
        if let image = task.updatedImage {
            doc.setValue(Blob.init(contentType: "image/jpeg", data: image), forKey: "image")
        }
        try tasksColl.save(document: doc)
    }
    
    public func updateTask(_ task: Task) throws {
        guard let doc = try tasksColl.document(id: task.id!)?.toMutable() else {
            throw AppLogicError.notFound
        }
        doc.setValue(task.task, forKey: "task")
        doc.setValue(task.complete, forKey: "complete")
        if let image = task.updatedImage {
            doc.setValue(Blob.init(contentType: "image/jpeg", data: image), forKey: "image")
        } else if task.image == nil {
            doc.removeValue(forKey: "image")
        }
        try tasksColl.save(document: doc)
    }
    
    public func deleteTask(_ task: Task) throws {
        if let doc = try tasksColl.document(id: task.id!) {
            try tasksColl.delete(document: doc)
        }
    }
    
    private func tasksQuery(for taskList: TaskList) throws -> Query {
        let query = "SELECT meta().id, task, complete, image, createdAt, taskList.id as taskListID, taskList.owner " +
                    "FROM \(tasksColl.name) " +
                    "WHERE taskList.id == '\(taskList.id)' " +
                    "ORDER BY createdAt, task"
        return try db.createQuery(query)
    }
    
    public func getTasksQuery(for taskList: TaskList) throws -> LiveQueryObject {
        return try LiveQuery.init(tasksQuery(for: taskList))
    }
    
    public func getTasks(for taskList: TaskList) throws -> [Task] {
        let query = try tasksQuery(for: taskList)
        return try query.execute().map { result in Task(result: QueryResult(result)) }
    }
    
    public func addUser(_ username: String, for taskList: TaskList) throws {
        let doc = MutableDocument(id: taskList.id + "." + username)
        doc.setValue(username, forKey: "username")
        doc.setValue(["id": taskList.id, "owner": taskList.owner], forKey: "taskList")
        try usersColl.save(document: doc)
    }
    
    public func deleteUser(_ user: User) throws {
        if let doc = try usersColl.document(id: user.id) {
            try usersColl.delete(document: doc)
        }
    }
    
    private func usersQuery(for taskList: TaskList) throws -> Query {
        let query = "SELECT meta().id, username, taskList.id as taskListID, taskList.owner " +
                    "FROM \(usersColl.name) " +
                    "WHERE taskList.id == '\(taskList.id)' " +
                    "ORDER BY username"
        return try db.createQuery(query)
    }
    
    public func getUsersQuery(for taskList: TaskList) throws -> LiveQueryObject {
        return try LiveQuery.init(usersQuery(for: taskList))
    }
    
    public func getUsers(for taskList: TaskList) throws -> [User] {
        let query = try usersQuery(for: taskList)
        return try query.execute().map { result in User(result: QueryResult(result)) }
    }
    
    private func replicatorConfiguration(continuous: Bool) -> ReplicatorConfiguration {
        let target = URLEndpoint(url: URL(string: Config.shared.syncURL)!)
        var config = ReplicatorConfiguration(target: target)
        config.continuous = continuous
        config.authenticator = BasicAuthenticator(username: username, password: password)
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
        
        var collConfig = CollectionConfiguration()
        collConfig.conflictResolver = conflictResolver
        config.addCollections([taskListsColl, tasksColl, usersColl], config: collConfig)
        
        return config
    }
}

fileprivate class BlobObject : BlobProtocol {
    private let blob: Blob
    
    init(_ blob: Blob) {
        self.blob = blob
    }
    
    func content() -> Data {
        return blob.content!
    }
    
    func digest() -> String {
        return blob.digest!
    }
}

fileprivate class QueryResult: QueryResultProtocol {
    public let id: String
    
    private let result: Result
    
    init(_ result: Result) {
        guard let id = result.string(forKey: "id") else {
            fatalError("Could not get docID from Query result")
        }
        self.id = id
        self.result = result
    }
    
    func string(forKey key: String) -> String? {
        return result.string(forKey: key)
    }
    
    func bool(forKey key: String) -> Bool {
        return result.boolean(forKey: key)
    }
    
    func date(forKey key: String) -> Date? {
        return result.date(forKey: key)
    }
    
    func blob(forKey key: String) -> BlobProtocol? {
        guard let rawBlob = result.blob(forKey: key) else {
            return nil
        }
        return BlobObject(rawBlob)
    }
}

fileprivate class QueryResultSet: QueryResultSetProtocol {
    let results: [any QueryResultProtocol]
    
    private let rs: ResultSet? // Retain the original result set object
    
    init(_ rs: ResultSet? = nil) {
        self.rs = rs
        if let rs = rs {
            self.results = Array<any QueryResultProtocol>(rs.map({ QueryResult($0) }))
        } else {
            self.results = []
        }
    }
}

fileprivate class LiveQuery : LiveQueryObject {
    private let query: Query
    
    private var token: ListenerToken?
    
    init(_ query: Query) {
        self.query = query
        
        super.init(change: QueryResultSet())
        
        token = self.query.addChangeListener({ [weak self] change in
            if let err = change.error {
                AppController.logger.log("[Todo] Query Error: \(query.description), \(err.localizedDescription)")
            }
            self?.change = QueryResultSet(change.results)
        })
    }
    
    deinit {
        token?.remove()
    }
}

fileprivate class TestConflictResolver: ConflictResolverProtocol {
    let _resolver: (Conflict) -> Document?
    
    init(_ resolver: @escaping (Conflict) -> Document?) {
        _resolver = resolver
    }
    
    func resolve(conflict: Conflict) -> Document? {
        return _resolver(conflict)
    }
}
