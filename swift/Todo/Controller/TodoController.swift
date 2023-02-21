//
//  TaskController.swift
//  Todo
//
//  Created by Callum Birks on 20/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI
import CouchbaseLiteSwift

// An interface between the UI and the DB class. A class that calls functions from this one should
// implement TaskControllerDelegate (in order to present an error)

class TodoController {
    
// - MARK: Queries
    
    public static func taskListsQuery() -> ObservableQuery {
        guard let query = try? DB.shared.getTaskListsQuery()
        else {
            fatalError("Could not get task lists query")
        }
        return ObservableQuery(query)
    }
    
    public static func tasksQuery(forList taskListID: String) -> ObservableQuery {
        guard let query = try? DB.shared.getTasksQuery(taskListID: taskListID)
        else {
            fatalError("Could not get tasks query for task list ID: \(taskListID)")
        }
        return ObservableQuery(query)
    }
    
    public static func usersQuery(forList taskListID: String) -> ObservableQuery {
        guard let query = try? DB.shared.getSharedUsersQuery(taskList: getTaskListDoc(fromID: taskListID))
        else {
            fatalError("Could not get shared users for task list with ID: \(taskListID)")
        }
        return ObservableQuery(query)
    }
    
// - MARK: Fetch documents by ID
    
    public static func getTaskListDoc(fromID taskListID: String) -> Document {
        do {
            guard let taskListDoc = try DB.shared.getTaskListByID(id: taskListID)
            else {
                fatalError("Couldn't fetch task list with ID: \(taskListID)")
            }
            return taskListDoc
        } catch {
            fatalError("Error fetching task list: \(error.localizedDescription)")
        }
    }
    
    public static func getTaskDoc(fromID taskID: String) -> Document {
        do {
            guard let taskDoc = try DB.shared.getTaskByID(id: taskID)
            else {
                fatalError("Couldn't fetch task with ID: \(taskID)")
            }
            return taskDoc
        } catch {
            fatalError("Error fetching task: \(error.localizedDescription)")
        }
    }
    
// - MARK: Common Task functions
    
    public static func generateTasks(taskListID: String, withPhoto: Bool, delegate: TaskControllerDelegate) {
        do {
            let taskListDoc = getTaskListDoc(fromID: taskListID)
            try DB.shared.generateTasks(taskList: taskListDoc, numbers: 50, includesPhoto: withPhoto)
        } catch {
            delegate.presentError(error, message: "Error generating tasks, with photo: \(withPhoto)")
        }
    }
    
    public static func createTask(withName name: String, inTaskList taskListID: String, delegate: TaskControllerDelegate) {
        do {
            let taskListDoc = getTaskListDoc(fromID: taskListID)
            try DB.shared.createTask(taskList: taskListDoc, task: name)
        } catch {
            delegate.presentError(error, message: "Couldn't create task")
        }
    }
    
    public static func deleteTask(taskID: String, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.deleteTask(taskID: taskID)
        } catch {
            delegate.presentError(error, message: "Couldn't delete task")
        }
    }
    
    public static func updateTask(taskID: String, name: String, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.updateTask(taskID: taskID, task: name)
        } catch {
            delegate.presentError(error, message: "Couldn't update task name")
        }
    }
    
    public static func updateTask(taskID: String, complete: Bool, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.updateTask(taskID: taskID, complete: complete)
        } catch {
            delegate.presentError(error, message: "Couldn't update task completion")
        }
    }
    
    public static func updateTask(taskID: String, image: UIImage, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.updateTask(taskID: taskID, image: image)
        } catch {
            delegate.presentError(error, message: "Couldn't update task image")
        }
    }
    
    public static func toggleTaskComplete(taskID: String, delegate: TaskControllerDelegate) {
        let taskDoc = getTaskDoc(fromID: taskID)
        let complete = taskDoc.boolean(forKey: "complete")
        TodoController.updateTask(taskID: taskID, complete: !complete, delegate: delegate)
    }
    
    public static func deleteImage(taskID: String) {
        do {
            try DB.shared.updateTask(taskID: taskID, image: nil)
        } catch {
            AppController.logger.log("Error deleting image: \(error.localizedDescription)")
        }
    }
    
// - MARK: Common Task List functions
    
    public static func createTaskList(withName name: String, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.createTaskList(name: name.capitalized)
        } catch {
            delegate.presentError(error, message: "Couldn't save task list")
        }
    }
    
    public static func updateTaskList(withID docID: String, name: String, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.updateTaskList(listID: docID, name: name.capitalized)
        } catch {
            delegate.presentError(error, message: "Couldn't update task list")
        }
    }
    
    public static func deleteTaskList(withID docID: String, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.deleteTaskList(listID: docID)
        } catch {
            delegate.presentError(error, message: "Couldn't delete task list")
        }
    }
    
// - MARK: Common User Functions
    
    public static func addUser(toTaskList taskListID: String, username: String, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.addSharedUser(taskList: getTaskListDoc(fromID: taskListID), username: username)
        } catch {
            delegate.presentError(error, message: "Couldn't add user to task list")
        }
    }
    
    public static func deleteSharedUser(userID: String, delegate: TaskControllerDelegate) {
        do {
            try DB.shared.deleteSharedUser(userID: userID)
        } catch {
            delegate.presentError(error, message: "Couldn't delete user")
        }
    }
}

protocol TaskControllerDelegate {
    func presentError(_ err: Error, message: String)
}
