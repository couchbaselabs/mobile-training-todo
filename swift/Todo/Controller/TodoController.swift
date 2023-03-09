//
// TodoController.swift
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

// An interface between the UI and the DB class. A class that calls functions from this one should
// implement TaskControllerDelegate (in order to present an error)

class TodoController {
    // - MARK: Queries
    
    public static func taskListsQuery() -> LiveQueryObject {
        do {
            return try AppLogic.shared.getTaskListsQuery()
        } catch {
            fatalError("Couldn't get task lists query: \(error.localizedDescription)")
        }
    }
    
    public static func tasksQuery(for taskList: TaskList) -> LiveQueryObject {
        do {
            return try AppLogic.shared.getTasksQuery(for: taskList)
        } catch {
            fatalError("Couldn't get tasks query: \(error.localizedDescription)")
        }
    }
    
    public static func usersQuery(for taskList: TaskList) -> LiveQueryObject {
        do {
            return try AppLogic.shared.getUsersQuery(for: taskList)
        } catch {
            fatalError("Couldn't get users query: \(error.localizedDescription)")
        }
    }
    
    // - MARK: Common Task functions
    
    public static func generateTasks(for taskList: TaskList, withPhoto: Bool, numbers: UInt, delegate: TodoControllerDelegate) {
        do {
            for i in 1...numbers {
                try autoreleasepool {
                    var task = Task(task: "Task \(i)",
                                    complete: (i % 2) == 0,
                                    createdAt: Date(),
                                    taskListID: taskList.id,
                                    owner: taskList.owner)
                    if withPhoto {
                        let data = dataFromResource(name: "\(i % 10)", ofType: "JPG") as Data
                        task.updatedImage = data
                    }
                    try AppLogic.shared.createTask(task)
                }
            }
        } catch {
            delegate.presentError(message: "Error generating tasks, with photo: \(withPhoto)", error)
        }
    }
    
    public static func createTask(name task: String, for taskList: TaskList, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.createTask(task, for: taskList)
        } catch {
            delegate.presentError(message: "Couldn't create task", error)
        }
    }
    
    public static func deleteTask(_ task: Task, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.deleteTask(task)
        } catch {
            delegate.presentError(message: "Couldn't delete task", error)
        }
    }
    
    public static func updateTask(_ task: Task, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.updateTask(task)
        } catch {
            delegate.presentError(message: "Couldn't update task", error)
        }
    }
    
    public static func updateTask(_ task: Task, image: UIImage?, delegate: TodoControllerDelegate) {
        do {
            var updated = task
            if let image = image {
                guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
                    throw DBError.invalidImage
                }
                updated.updatedImage = imageData
            } else {
                updated.image = nil
                updated.updatedImage = nil
            }
            try AppLogic.shared.updateTask(updated)
        } catch {
            delegate.presentError(message: "Couldn't update task list", error)
        }
    }
    
    // - MARK: Common Task List functions
    
    public static func createTaskList(name: String, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.createTaskList(name: name)
        } catch {
            delegate.presentError(message: "Couldn't create task list", error)
        }
    }
    
    public static func updateTaskList(_ taskList: TaskList, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.updateTaskList(taskList)
        } catch {
            delegate.presentError(message: "Couldn't update task list", error)
        }
    }
    
    public static func deleteTaskList(_ taskList: TaskList, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.deleteTaskList(taskList)
        } catch {
            delegate.presentError(message: "Couldn't delete task list", error)
        }
    }
     
    // - MARK: Common User Functions
    
    public static func addUser(_ username: String, for taskList: TaskList, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.addUser(username, for: taskList)
        } catch {
            delegate.presentError(message: "Couldn't add user to task list", error)
        }
    }
    
    public static func deleteUser(_ user: User, delegate: TodoControllerDelegate) {
        do {
            try AppLogic.shared.deleteUser(user)
        } catch {
            delegate.presentError(message: "Couldn't delete user", error)
        }
    }
    
    // MARK: Debug
    
    public static func logTaskList(_ taskList: TaskList) {
        do {
            let tasks = try AppLogic.shared.getTasks(for: taskList)
            let users = try AppLogic.shared.getUsers(for: taskList)
            
            print("Task List : ")
            print(" id : \(taskList.id)")
            print(" name : \(taskList.name)")
            print(" owner : \(taskList.owner)")
            print("")
            print("Number of Tasks: \(tasks.count)")
            print("")
            var i = 0;
            for task in tasks {
                i = i + 1;
                print("Task #\(i):")
                print(" id: \(task.id!)")
                print(" task: \(task.task)")
                print(" complete: \(task.complete)")
                if let image = task.image {
                    print(" image: \(image.digest())")
                }
                print(" taskListID: \(task.taskListID)")
                print(" taskListOwner: \(task.owner)")
                print("")
            }
            print("Number of Users: \(users.count)")
            print("")
            i = 0;
            for user in users {
                i = i + 1;
                print("User #\(i):")
                print(" id: \(user.id)")
                print(" username: \(user.username)")
                print(" taskListID: \(user.taskListID)")
                print(" taskListOwner: \(user.owner)")
                print("")
            }
        } catch {
            fatalError("Couldn't get task: \(error.localizedDescription)")
        }
    }
    
    public static func logTask(_ task: Task) {
        print("Task: \(task.id!)")
        print(" task: \(task.task)")
        print(" complete: \(task.complete)")
        if let image = task.image {
            print(" image: \(image.digest())")
        }
        print(" taskListID: \(task.taskListID)")
        print(" taskListOwner: \(task.owner)")
    }
    
    // MARK: Utils
    
    private static func dataFromResource(name: String, ofType: String) -> NSData {
        let path = Bundle.main.path(forResource: name, ofType: ofType)
        return try! NSData(contentsOfFile: path!, options: [])
    }
}

protocol TodoControllerDelegate {
    func presentError(message: String, _ err: Error?)
}
