//
// Log.swift
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

func logTaskList(id: String) throws {
    guard let doc = try DB.shared.getTaskListByID(id: id) else {
        print("No Task List ID \(id)")
        return
    }
    
    let tasks = try DB.shared.getTasks(taskListID: id).allResults()
    let users = try DB.shared.getSharedUsers(taskListID: id).allResults()
    
    print(">>>>>>>> TASK LIST LOG START <<<<<<<<")
    print("")
    print("Task List Doc: \(taskListBody(doc: doc))")
    print("")
    print("Number of Tasks: \(tasks.count)")
    print("")
    
    var i = 0;
    for task in tasks {
        i = i + 1;
        let taskID = task.string(at: 0)!
        if let taskDoc = try DB.shared.getTaskByID(id: taskID) {
            print("> Task Doc #\(i) : \(taskBody(doc: taskDoc))");
        } else {
            print("> Task Doc #\(i) : << N/A >>")
        }
        print("")
    }
    
    print("Number of Users: \(users.count)");
    print("")
    i = 0;
    for user in users {
        i = i + 1;
        let userID = user.string(at: 0)!
        if let userDoc = try DB.shared.getSharedUserByID(id: userID) {
            print("> User Doc #\(i) : \(userBody(doc: userDoc))");
        } else {
            print("> User Doc #\(i) : << N/A >>")
        }
        print("")
    }
}

func logTask(id: String) throws {
    guard let doc = try DB.shared.getTaskByID(id: id) else {
        print("No Task ID \(id)")
        return
    }
    
    print(">>>>>>>> TASK LOG START <<<<<<<<");
    print("")
    print("> Task Doc: \(taskBody(doc: doc))");
    print("")
    print(">>>>>>>> TASK LOG END <<<<<<<<");
}

func taskListBody(doc: Document) -> Dictionary<String, Any> {
    var body = doc.toDictionary()
    body["_id"] = doc.id
    return body
}

func taskBody(doc: Document) -> Dictionary<String, Any> {
    var body = doc.toDictionary()
    body["_id"] = doc.id
    if let blob = body["image"] as? Blob {
        body["iamge"] = blob.properties
    }
    return body
}

func userBody(doc: Document) -> Dictionary<String, Any> {
    var body = doc.toDictionary()
    body["_id"] = doc.id
    return body
}
