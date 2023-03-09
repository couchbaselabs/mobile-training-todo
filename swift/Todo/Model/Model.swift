//
// Model.swift
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

public protocol BlobProtocol {
    func content() -> Data
    func digest() -> String
}

public struct TaskList {
    public var id: String
    
    public var name: String
    
    public var owner: String
    
    init(result: any QueryResultProtocol) {
        id = result.string(forKey: "id")!
        name = result.string(forKey: "name")!
        owner = result.string(forKey: "owner")!
    }
}

public struct Task {
    public var id: String?
    
    public var task: String
    
    public var complete: Bool
    
    public var image: BlobProtocol?
    
    public var updatedImage: Data?
    
    public var createdAt: Date
    
    public var taskListID: String
    
    public var owner: String
    
    init(task: String, complete: Bool, createdAt: Date, taskListID: String, owner: String) {
        self.task = task
        self.complete = complete
        self.createdAt = createdAt
        self.taskListID = taskListID
        self.owner = owner
    }
    
    init(result: any QueryResultProtocol) {
        id = result.string(forKey: "id")
        task = result.string(forKey: "task")!
        complete = result.bool(forKey: "complete")
        image = result.blob(forKey: "image")
        createdAt = result.date(forKey: "createdAt")!
        
        // Note: Expect the query to flaten the task list info:
        taskListID = result.string(forKey: "taskListID")!
        owner = result.string(forKey: "owner")!
    }
}

extension Task: Equatable {
    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct User {
    public var id: String
    
    public var username: String
    
    public var taskListID: String
    
    public var owner: String
    
    init(result: any QueryResultProtocol) {
        id = result.string(forKey: "id")!
        username = result.string(forKey: "username")!
        
        // Note: Expect the query to flaten the task list info:
        taskListID = result.string(forKey: "taskListID")!
        owner = result.string(forKey: "owner")!
    }
}
