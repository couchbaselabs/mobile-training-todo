//
// AppLogic.swift
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

public enum DBError: Error {
    case notFound
    case invalidImage
}

public protocol QueryResultProtocol : Identifiable {
    var id: String { get }
    func string(forKey key: String) -> String?
    func bool(forKey key: String) -> Bool
    func date(forKey key: String) -> Date?
    func blob(forKey key: String) -> BlobProtocol?
}

public protocol QueryResultSetProtocol {
    var results: [any QueryResultProtocol] { get }
}

public class LiveQueryObject : ObservableObject {
    @Published var change: QueryResultSetProtocol
    
    public init(change: QueryResultSetProtocol) {
        self.change = change
    }
}

public protocol AppLogicProtocol {
    func open() throws
    
    func close() throws
    
    func delete() throws
    
    func startReplicator() throws
    
    func createTaskList(name: String) throws
    
    func updateTaskList(_ taskList: TaskList) throws
    
    func deleteTaskList(_ taskList: TaskList) throws
    
    func getTaskListsQuery() throws -> LiveQueryObject
    
    func createTask(_ task: String, for taskList: TaskList) throws
    
    func createTask(_ task: Task) throws
    
    func updateTask(_ task: Task) throws
    
    func deleteTask(_ task: Task) throws
    
    func getTasksQuery(for taskList: TaskList) throws -> LiveQueryObject
    
    func getTasks(for taskList: TaskList) throws -> [Task]
    
    func addUser(_ username: String, for taskList: TaskList) throws
    
    func deleteUser(_ user: User) throws
    
    func getUsersQuery(for taskList: TaskList) throws -> LiveQueryObject
    
    func getUsers(for taskList: TaskList) throws -> [User]
}

public protocol AppLogicDelegateProtocol : AppLogicProtocol {
    init(username: String, password: String)
}

public class AppLogic : AppLogicProtocol {
    public static let shared = AppLogic()
    
    private var logic: AppLogicDelegateProtocol!
    
    private init() { }
    
    // MARK: Database
    
    public func open() throws {
        if !Session.shared.isLoggedIn {
            fatalError("No User Logged In")
        }
        
        if logic != nil {
            fatalError("Database is already opened")
        }
        
        logic = AppLogicDelegate(username: Session.shared.username, password: Session.shared.password)
        try logic.open()
    }
    
    public func close() throws {
        try logic.close()
        logic = nil
    }
    
    public func delete() throws {
        try logic.delete()
        logic = nil
    }
    
    // MARK: Replicator
    
    public func startReplicator() throws {
        try logic.startReplicator()
    }
    
    // MARK: Task Lists
    
    public func createTaskList(name: String) throws {
        try logic.createTaskList(name: name)
    }
    
    public func updateTaskList(_ taskList: TaskList) throws {
        try logic.updateTaskList(taskList)
    }
    
    public func deleteTaskList(_ taskList: TaskList) throws {
        try logic.deleteTaskList(taskList)
    }
    
    public func getTaskListsQuery() throws -> LiveQueryObject {
        return try logic.getTaskListsQuery()
    }
    
    // MARK: Tasks
    
    public func createTask(_ task: String, for taskList: TaskList) throws {
        return try logic.createTask(task, for: taskList)
    }
    
    public func createTask(_ task: Task) throws {
        return try logic.createTask(task)
    }
    
    public func updateTask(_ task: Task) throws {
        try logic.updateTask(task)
    }
    
    public func deleteTask(_ task: Task) throws {
        try logic.deleteTask(task)
    }
    
    public func getTasksQuery(for taskList: TaskList) throws -> LiveQueryObject {
        return try logic.getTasksQuery(for: taskList)
    }
    
    public func getTasks(for taskList: TaskList) throws -> [Task] {
        return try logic.getTasks(for: taskList)
    }
    
    // MARK: Users
    
    public func addUser(_ username: String, for taskList: TaskList) throws {
        try logic.addUser(username, for: taskList)
    }
    
    public func deleteUser(_ user: User) throws {
        try logic.deleteUser(user)
    }
    
    public func getUsersQuery(for taskList: TaskList) throws -> LiveQueryObject {
        return try logic.getUsersQuery(for: taskList)
    }
    
    public func getUsers(for taskList: TaskList) throws -> [User] {
        return try logic.getUsers(for: taskList)
    }
}
