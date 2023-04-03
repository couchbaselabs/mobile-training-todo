//
// AppLogic-C.swift
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
import CouchbaseLite

public class AppLogicDelegate : AppLogicDelegateProtocol {
    let username: String
    let password: String
    
    private var database: OpaquePointer?
    
    private var taskListsColl: OpaquePointer!
    private var tasksColl: OpaquePointer!
    private var usersColl: OpaquePointer!
    
    private var replicator: OpaquePointer?
    private var replicatorChangeListener: OpaquePointer?
    
    public required init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    deinit {
        CBLCollection_Release(taskListsColl)
        CBLCollection_Release(tasksColl)
        CBLCollection_Release(usersColl)
        CBLDatabase_Release(database)
    }
    
    public func open() throws {
        if database != nil {
            fatalError("Database is already open")
        }
        
        if Config.shared.loggingEnabled {
            CBLLog_SetConsoleLevel(.info)
        }
        
        // Open database:
        try username.withSlice { user in
            var err = CBLError()
            var config = CBLDatabaseConfiguration_Default()
            guard let openedDB = CBLDatabase_Open(user, &config, &err) else {
                throw err.throwable()
            }
            self.database = openedDB
            print("\(CBLDatabase_Path(self.database!).stringVal())")
        }
        
        // Create or get collections:
        taskListsColl = try createCollection("lists")
        tasksColl = try createCollection("tasks")
        usersColl = try createCollection("users")
        
        // Create Indexes:
        try createValueIndex("lists", expression: "name")
        try createValueIndex("tasks", expression: "taskList.id, task")
    }
    
    public func close() throws {
        try withDatabase { db, err in
            CBLDatabase_Close(db, err)
        }
    }
    
    public func delete() throws {
        try withDatabase { db, err in
            CBLDatabase_Delete(db, err)
        }
    }
    
    public func startReplicator() throws {
        var err = CBLError()
        let endpoint = CBLEndpoint_CreateWithURL(FLS(Config.shared.syncURL).sl(), nil)!
        let auth = CBLAuth_CreatePassword(FLS(username).sl(), FLS(password).sl())
        
        var config = replicatorConfiguration(endpoint: endpoint, auth: auth)
        replicator = CBLReplicator_Create(&config, &err)
        replicatorChangeListener = CBLReplicator_AddChangeListener(replicator!, { context, repl, status in
            let kActivities = ["Stopped", "Offline", "Connecting", "Idle", "Busy"]
            let s = status.pointee
            let activity = kActivities[Int(s.activity.rawValue)]
            var e = s.error
            var errMesg = ""
            if e.code != 0 {
                errMesg = ", error code = \(s.error.code), message = \(CBLError_Message(&e).stringVal())"
            }
            AppController.logger.log("[Todo] Replicator: \(activity), \(s.progress.complete)\(errMesg)")
        }, nil)
        CBLReplicator_Start(replicator!, false)
        
        CBLEndpoint_Free(endpoint)
        CBLAuth_Free(auth)
    }
    
    private func replicatorConfiguration(endpoint: OpaquePointer, auth: OpaquePointer) -> CBLReplicatorConfiguration {
        var conflictR: CBLConflictResolver?
        if Config.shared.ccrEnabled {
            conflictR = { context, docID, localDoc, remoteDoc in
                switch Config.shared.ccrType {
                case .local:
                    return localDoc
                case .remote:
                    return remoteDoc
                case .delete:
                    return nil;
                }
            }
        }
        // TODO : Setup conflict resolver based on the Config.shared.ccrEnabled and Config.shared.ccrType
        var collections = [
            CBLReplicationCollection(collection: taskListsColl, conflictResolver: conflictR, pushFilter: nil, pullFilter: nil, channels: nil, documentIDs: nil),
            CBLReplicationCollection(collection: tasksColl, conflictResolver: conflictR, pushFilter: nil, pullFilter: nil, channels: nil, documentIDs: nil),
            CBLReplicationCollection(collection: usersColl, conflictResolver: conflictR, pushFilter: nil, pullFilter: nil, channels: nil, documentIDs: nil)
        ]
        let collectionsPtr = UnsafeMutablePointer<CBLReplicationCollection>.allocate(capacity: collections.count)
        collectionsPtr.initialize(from: &collections, count: collections.count)
        
        return CBLReplicatorConfiguration.init(
            database: nil,
            endpoint: endpoint,
            replicatorType: CBLReplicatorType.pushAndPull,
            continuous: true,
            disableAutoPurge: false,
            maxAttempts: UInt32(Config.shared.maxAttempts),
            maxAttemptWaitTime: UInt32(Config.shared.maxAttemptWaitTime),
            heartbeat: 0,
            authenticator: auth,
            proxy: nil,
            headers: nil,
            pinnedServerCertificate: FLSlice(buf: nil, size: 0),
            trustedRootCertificates: FLSlice(buf: nil, size: 0),
            channels: nil,
            documentIDs: nil,
            pushFilter: nil,
            pullFilter: nil,
            conflictResolver: nil,
            context: nil,
            propertyEncryptor: nil,
            propertyDecryptor: nil,
            documentPropertyEncryptor: nil,
            documentPropertyDecryptor: nil,
            collections: collectionsPtr,
            collectionCount: collections.count,
            acceptParentDomainCookies: false)
    }
    
    public func createTaskList(name: String) async throws {
        let docID = username + "." + UUID().uuidString
        
        let role = "lists." + docID + ".contributor"
        try await SGAdmin.shared.createRole(role)
        
        try withCollection(taskListsColl, block: { coll, err in
            let doc = CBLDocument_CreateWithID(FLS(docID).sl())
            defer { CBLDocument_Release(doc) }
            let props = CBLDocument_MutableProperties(doc)
            FLMutableDict_SetString(props, FLS("name").sl(), FLS(name).sl())
            FLMutableDict_SetString(props, FLS("owner").sl(), FLS(username).sl())
            return CBLCollection_SaveDocument(coll, doc, err)
        })
    }
    
    public func updateTaskList(_ taskList: TaskList) throws {
        try withCollection(taskListsColl, block: { coll, err in
            guard let doc = CBLCollection_GetMutableDocument(coll, FLS(taskList.id).sl(), err) else {
                throw AppLogicError.notFound
            }
            let props = CBLDocument_MutableProperties(doc)
            FLMutableDict_SetString(props, FLS("name").sl(), FLS(taskList.name).sl())
            return CBLCollection_SaveDocument(coll, doc, err)
        })
    }
    
    public func deleteTaskList(_ taskList: TaskList) throws {
        try withCollection(taskListsColl, block: { coll, err in
            if let doc = CBLCollection_GetMutableDocument(coll, FLS(taskList.id).sl(), err) {
                return CBLCollection_DeleteDocument(coll, doc, err)
            }
            return true
        })
    }
    
    public func getTaskListsQuery() throws -> LiveQueryObject {
        let queryStr = "SELECT meta().id, name, owner FROM \(collectionName(taskListsColl)) ORDER BY name"
        let query = try withDatabase { db, err in
            return CBLDatabase_CreateQuery(db, .cbln1QLLanguage, FLS(queryStr).sl(), nil, err)
        }
        return LiveQuery(adopt: query)
    }
    
    public func createTask(_ task: String, for taskList: TaskList) throws {
        try withCollection(tasksColl, block: { coll, err in
            let doc = CBLDocument_Create()
            let props = CBLDocument_MutableProperties(doc)
            
            let taskListInfo = FLMutableDict_New()!
            FLMutableDict_SetString(taskListInfo, FLS("id").sl(), FLS(taskList.id).sl())
            FLMutableDict_SetString(taskListInfo, FLS("owner").sl(), FLS(taskList.owner).sl())
            FLMutableDict_SetDict(props, FLS("taskList").sl(), taskListInfo)
            
            FLMutableDict_SetString(props, FLS("task").sl(), FLS(task).sl())
            FLMutableDict_SetBool(props, FLS("complete").sl(), false)
            
            let now = FLTimestamp_ToString(FLTimestamp_Now(), true)
            FLMutableDict_SetString(props, FLS("createdAt").sl(), FLSliceResult_AsSlice(now))
            
            defer {
                FLSliceResult_Release(now)
                CBLDocument_Release(doc)
            }
            return CBLCollection_SaveDocument(coll, doc, err)
        })
    }
    
    public func createTask(_ task: Task) throws {
        try withCollection(tasksColl, block: { coll, err in
            let doc = CBLDocument_Create()
            let props = CBLDocument_MutableProperties(doc)
            
            let taskListInfo = FLMutableDict_New()!
            FLMutableDict_SetString(taskListInfo, FLS("id").sl(), FLS(task.taskListID).sl())
            FLMutableDict_SetString(taskListInfo, FLS("owner").sl(), FLS(task.owner).sl())
            FLMutableDict_SetDict(props, FLS("taskList").sl(), taskListInfo)
            
            FLMutableDict_SetString(props, FLS("task").sl(), FLS(task.task).sl())
            FLMutableDict_SetBool(props, FLS("complete").sl(), task.complete)
            
            let now = FLTimestamp_ToString(FLTimestamp_Now(), true)
            FLMutableDict_SetString(props, FLS("createdAt").sl(), FLSliceResult_AsSlice(now))
            
            var blob: OpaquePointer? = nil
            if let image = task.updatedImage {
                blob = CBLBlob_CreateWithData(FLS("image/jpg").sl(), FLS(image).sl())
                FLMutableDict_SetBlob(props, FLS("image").sl(), blob!)
            }
            
            defer {
                FLSliceResult_Release(now)
                CBLDocument_Release(doc)
            }
            return CBLCollection_SaveDocument(coll, doc, err)
        })
    }
    
    public func updateTask(_ task: Task) throws {
        try withCollection(tasksColl, block: { coll, err in
            guard let doc = CBLCollection_GetMutableDocument(coll, FLS(task.id!).sl(), err) else {
                throw AppLogicError.notFound
            }
            
            let props = CBLDocument_MutableProperties(doc)
            FLMutableDict_SetString(props, FLS("task").sl(), FLS(task.task).sl())
            FLMutableDict_SetBool(props, FLS("complete").sl(), task.complete)
            
            var blob: OpaquePointer? = nil
            if let image = task.updatedImage {
                blob = CBLBlob_CreateWithData(FLS("image/jpg").sl(), FLS(image).sl())
                FLMutableDict_SetBlob(props, FLS("image").sl(), blob!)
            } else if task.image == nil {
                FLMutableDict_Remove(props, FLS("image").sl())
            }
            
            defer {
                CBLBlob_Release(blob)
            }
            return CBLCollection_SaveDocument(coll, doc, err)
        })
    }
    
    public func deleteTask(_ task: Task) throws {
        try withCollection(tasksColl, block: { coll, err in
            if let doc = CBLCollection_GetMutableDocument(coll, FLS(task.id!).sl(), err) {
                return CBLCollection_DeleteDocument(coll, doc, err)
            }
            return true
        })
    }
    
    private func tasksQuery(for taskList: TaskList) throws -> OpaquePointer {
        let queryStr = "SELECT meta().id, task, complete, image, createdAt, taskList.id as taskListID, taskList.owner " +
                       "FROM \(collectionName(tasksColl)) " +
                       "WHERE taskList.id == '\(taskList.id)' " +
                       "ORDER BY createdAt, task"
        return try withDatabase { db, err in
            return CBLDatabase_CreateQuery(db, .cbln1QLLanguage, FLS(queryStr).sl(), nil, err)
        }
    }
    
    public func getTasksQuery(for taskList: TaskList) throws -> LiveQueryObject {
        return LiveQuery(adopt: try tasksQuery(for: taskList))
    }
    
    public func getTasks(for taskList: TaskList) throws -> [Task] {
        let query = try tasksQuery(for: taskList)
        var err = CBLError()
        guard let rs = CBLQuery_Execute(query, &err) else {
            throw err.throwable()
        }
        
        var tasks: [Task] = []
        while (CBLResultSet_Next(rs)) {
            let dict = CBLResultSet_ResultDict(rs)
            tasks.append(Task.init(result: QueryResult(dict)))
        }
        CBLQuery_Release(query);
        return tasks
    }
    
    public func addUser(_ username: String, for taskList: TaskList) throws {
        try withCollection(usersColl, block: { coll, err in
            let doc = CBLDocument_CreateWithID(FLS(taskList.id + "." + username).sl())
            let props = CBLDocument_MutableProperties(doc)
           
            FLMutableDict_SetString(props, FLS("username").sl(), FLS(username).sl())
            
            let dict = FLMutableDict_New()!
            FLMutableDict_SetString(dict, FLS("id").sl(), FLS(taskList.id).sl())
            FLMutableDict_SetString(dict, FLS("owner").sl(), FLS(taskList.owner).sl())
            FLMutableDict_SetDict(props, FLS("taskList").sl(), dict)
            
            defer {
                FLMutableDict_Release(dict);
                CBLDocument_Release(doc)
            }
            
            return CBLCollection_SaveDocument(coll, doc, err)
        })
    }
    
    public func deleteUser(_ user: User) throws {
        try withCollection(usersColl, block: { coll, err in
            if let doc = CBLCollection_GetDocument(coll, FLS(user.id).sl(), err){
                return CBLCollection_DeleteDocument(coll, doc, err)
            }
            return true
        })
    }
    
    private func usersQuery(for taskList: TaskList) throws -> OpaquePointer {
        let queryStr = "SELECT meta().id, username, taskList.id as taskListID, taskList.owner " +
                    "FROM \(collectionName(usersColl)) " +
                    "WHERE taskList.id == '\(taskList.id)' " +
                    "ORDER BY username"
        return try withDatabase { db, err in
            return CBLDatabase_CreateQuery(db, .cbln1QLLanguage, FLS(queryStr).sl(), nil, err)
         }
    }
    
    public func getUsersQuery(for taskList: TaskList) throws -> LiveQueryObject {
        return LiveQuery(adopt: try usersQuery(for: taskList))
    }
    
    public func getUsers(for taskList: TaskList) throws -> [User] {
        let query = try usersQuery(for: taskList)
        var err = CBLError()
        guard let rs = CBLQuery_Execute(query, &err) else {
            throw err.throwable()
        }
        
        var users: [User] = []
        while (CBLResultSet_Next(rs)) {
            let dict = CBLResultSet_ResultDict(rs)
            users.append(User.init(result: QueryResult(dict)))
        }
        CBLQuery_Release(query);
        return users
    }
    
    // MARK : Database Function Helpers
    
    private func openedDB() -> OpaquePointer {
        guard let db = self.database else {
            fatalError("Database is not opened")
        }
        return db
    }
    
    private func withDatabase(_ block:(_ db: OpaquePointer, _ err: UnsafeMutablePointer<CBLError>) throws -> OpaquePointer?) throws -> OpaquePointer {
        let openedDB = openedDB()
        var err = CBLError()
        guard let result = try block(openedDB, &err) else {
            throw err.throwable()
        }
        return result
    }

    private func withDatabase(_ block:(_ db: OpaquePointer, _ err: UnsafeMutablePointer<CBLError>) throws -> Bool) throws {
        let openedDB = openedDB()
        var err = CBLError()
        let success = try block(openedDB, &err)
        if (!success) {
            throw err.throwable()
        }
    }
    
    private func withCollection(_ collection: OpaquePointer, block:(_ coll: OpaquePointer, _ err: UnsafeMutablePointer<CBLError>) throws -> Bool) throws {
        var err = CBLError()
        let success = try block(collection, &err)
        if (!success) {
            throw err.throwable()
        }
    }
    
    private func collectionName(_ collection: OpaquePointer) -> String {
        return CBLCollection_Name(collection).string()
    }
    
    private func createCollection(_ name: String) throws -> OpaquePointer {
        return try name.withSlice { nameSlice in
            try withDatabase { db, err in
                return CBLDatabase_CreateCollection(db, nameSlice, FLS("_default").sl(), err)
            }
        }
    }
    
    private func createValueIndex(_ name: String, expression: String) throws {
        try withDatabase { db, err in
            let nameSlice = FLS(name)
            let expressionSlice = FLS(expression)
            let config = CBLValueIndexConfiguration(expressionLanguage: .cbln1QLLanguage, expressions: expressionSlice.sl())
            return CBLDatabase_CreateValueIndex(db, nameSlice.sl(), config, err)
        }
    }
    
    private func executeQuery(_ query: OpaquePointer) throws -> [any QueryResultProtocol] {
        var err = CBLError()
        guard let rs = CBLQuery_Execute(query, &err) else {
            throw err.throwable()
        }
        
        var results: [any QueryResultProtocol] = []
        while (CBLResultSet_Next(rs)) {
            let dict = CBLResultSet_ResultDict(rs)
            results.append(QueryResult.init(dict))
        }
        
        defer { CBLResultSet_Release(rs) }
        return results
    }
}

fileprivate class BlobObject : BlobProtocol {
    private let blob: OpaquePointer
    private let blobDigest: String
    
    init(_ blob: OpaquePointer) {
        self.blob = CBLBlob_Retain(blob)
        // Workaround : we have a case that accesses digest
        // without retaining query's result set when logging tasks
        self.blobDigest = CBLBlob_Digest(blob).string()
    }
    
    deinit {
        CBLBlob_Release(blob)
    }
    
    func content() -> Data {
        let content = CBLBlob_Content(blob, nil)
        return content.data()!
    }
    
    func digest() -> String {
        return CBLBlob_Digest(blob).string()
    }
}

fileprivate class QueryResult: QueryResultProtocol {
    public let id: String
    
    private let result: FLDict
    
    init(_ result: FLDict) {
        let idValue = FLDict_Get(result, FLS("id").sl())
        self.id = FLValue_AsString(idValue).string()
        self.result = FLDict_Retain(result)!
    }
    
    deinit {
        FLDict_Release(result)
    }
    
    func string(forKey key: String) -> String? {
        return key.withSlice { keySlice in
            let value = FLDict_Get(result, keySlice)
            return FLValue_AsString(value).string()
        }
    }
    
    func bool(forKey key: String) -> Bool {
        return key.withSlice { keySlice in
            let value = FLDict_Get(result, keySlice)
            return FLValue_AsBool(value)
        }
    }
    
    func date(forKey key: String) -> Date? {
        return key.withSlice { keySlice in
            let value = FLValue_AsString(FLDict_Get(result, keySlice))
            if value.buf != nil {
                let timestamp = FLTimestamp_FromString(value)
                return Date(timeIntervalSince1970: TimeInterval(timestamp))
            }
            return nil
        }
    }
    
    func blob(forKey key: String) -> BlobProtocol? {
        return key.withSlice { keySlice in
            let value = FLDict_Get(result, keySlice)
            guard let blob = FLValue_GetBlob(value) else {
                return nil
            }
            return BlobObject(blob)
        }
    }
}

fileprivate class QueryResultSet: QueryResultSetProtocol {
    let results: [any QueryResultProtocol]
    
    private let rs: OpaquePointer?
    
    init(_ rs: OpaquePointer? = nil) {
        self.rs = rs
        if let rs = rs {
            var results: [any QueryResultProtocol] = []
            while (CBLResultSet_Next(rs)) {
                let dict = CBLResultSet_ResultDict(rs)
                results.append(QueryResult.init(dict))
            }
            self.results = results
        } else {
            self.results = []
        }
    }
    
    deinit {
        CBLResultSet_Release(rs)
    }
}

fileprivate class LiveQuery : LiveQueryObject {
    private let query: OpaquePointer
    private var token: OpaquePointer?
    
    init(adopt query: OpaquePointer /* consumed */) {
        self.query = query
        
        super.init(change: QueryResultSet())
        
        token = CBLQuery_AddChangeListener(query, { context, query, token in
            let me = Unmanaged<LiveQuery>.fromOpaque(context!).takeUnretainedValue()
            var err = CBLError()
            let rs = CBLQuery_CopyCurrentResults(query, token, &err) // TODO: Log error
            me.setResults(rs)
        }, Unmanaged.passUnretained(self).toOpaque())
    }
    
    func setResults(_ results: OpaquePointer?) {
        DispatchQueue.main.sync {
            self.change = QueryResultSet.init(results) // Publish on the main thread
        }
    }
    
    deinit {
        CBLListener_Remove(token);
        CBLQuery_Release(query);
    }
}
