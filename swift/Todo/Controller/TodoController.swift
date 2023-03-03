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
        do {
            let query = try DB.shared.getTaskListsQuery()
            return ObservableQuery(query)
        } catch {
            fatalError("Couldn't get task lists query: \(error.localizedDescription)")
        }
    }
    
    public static func tasksQuery(forList taskListID: String) -> ObservableQuery {
        do {
            let query = try DB.shared.getTasksQuery(taskListID: taskListID)
            return ObservableQuery(query)
        } catch {
            fatalError("Couldn't get tasks query: \(error.localizedDescription)")
        }
    }
    
    public static func usersQuery(forList taskListID: String) -> ObservableQuery {
        do {
            let query = try DB.shared.getSharedUsersQuery(taskListID: taskListID)
            return ObservableQuery(query)
        } catch {
            fatalError("Couldn't get shared users query: \(error.localizedDescription)")
        }
    }
    
// - MARK: Fetch documents by ID
    
    public static func getTaskListDoc(fromID taskListID: String) -> Document? {
        if let taskListDoc = try? DB.shared.getTaskListByID(id: taskListID) {
            return taskListDoc
        }
        return nil
    }
    
    public static func getTaskDoc(fromID taskID: String) -> Document? {
        if let taskListDoc = try? DB.shared.getTaskByID(id: taskID) {
            return taskListDoc
        }
        return nil
    }
    
// - MARK: Common Task functions
    
    public static func generateTasks(taskListID: String, withPhoto: Bool, delegate: TodoControllerDelegate) {
        do {
            guard let taskListDoc = getTaskListDoc(fromID: taskListID)
            else {
                delegate.presentError(message: "Couldn't fetch task list doc", nil)
                return
            }
            try DB.shared.generateTasks(taskList: taskListDoc, numbers: 50, includesPhoto: withPhoto)
        } catch {
            delegate.presentError(message: "Error generating tasks, with photo: \(withPhoto)", error)
        }
    }
    
    public static func createTask(withName name: String, inTaskList taskListID: String, delegate: TodoControllerDelegate) {
        do {
            guard let taskListDoc = getTaskListDoc(fromID: taskListID)
            else {
                delegate.presentError(message: "Couldn't fetch task list doc", nil)
                return
            }
            try DB.shared.createTask(taskList: taskListDoc, task: name)
        } catch {
            delegate.presentError(message: "Couldn't create task", error)
        }
    }
    
    public static func deleteTask(taskID: String, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.deleteTask(taskID: taskID)
        } catch {
            delegate.presentError(message: "Couldn't delete task", error)
        }
    }
    
    public static func updateTask(taskID: String, name: String, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.updateTask(taskID: taskID, task: name)
        } catch {
            delegate.presentError(message: "Couldn't update task name", error)
        }
    }
    
    public static func updateTask(taskID: String, complete: Bool, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.updateTask(taskID: taskID, complete: complete)
        } catch {
            delegate.presentError(message: "Couldn't update task completion", error)
        }
    }
    
    public static func updateTask(taskID: String, image: UIImage, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.updateTask(taskID: taskID, image: image)
        } catch {
            delegate.presentError(message: "Couldn't update task image", error)
        }
    }
    
    public static func toggleTaskComplete(taskID: String, delegate: TodoControllerDelegate) {
        guard let taskDoc = getTaskDoc(fromID: taskID)
        else {
            delegate.presentError(message: "Couldn't fetch task doc", nil)
            return
        }
        let complete = taskDoc.boolean(forKey: "complete")
        TodoController.updateTask(taskID: taskID, complete: !complete, delegate: delegate)
    }
    
    public static func deleteImage(taskID: String) -> Bool {
        do {
            try DB.shared.updateTask(taskID: taskID, image: nil)
        } catch {
            AppController.logger.log("Error deleting image: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
// - MARK: Common Task List functions
    
    public static func createTaskList(withName name: String, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.createTaskList(name: name.capitalized)
        } catch {
            delegate.presentError(message: "Couldn't save task list", error)
        }
    }
    
    public static func updateTaskList(withID docID: String, name: String, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.updateTaskList(listID: docID, name: name.capitalized)
        } catch {
            delegate.presentError(message: "Couldn't update task list", error)
        }
    }
    
    public static func deleteTaskList(withID docID: String, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.deleteTaskList(listID: docID)
        } catch {
            delegate.presentError(message: "Couldn't delete task list", error)
        }
    }
    
// - MARK: Common User Functions
    
    public static func addUser(toTaskList taskListID: String, username: String, delegate: TodoControllerDelegate) {
        do {
            guard let taskListDoc = getTaskListDoc(fromID: taskListID)
            else {
                delegate.presentError(message: "Couldn't fetch task list doc", nil)
                return
            }
            try DB.shared.addSharedUser(taskList: taskListDoc, username: username)
        } catch {
            delegate.presentError(message: "Couldn't add user to task list", error)
        }
    }
    
    public static func deleteSharedUser(userID: String, delegate: TodoControllerDelegate) {
        do {
            try DB.shared.deleteSharedUser(userID: userID)
        } catch {
            delegate.presentError(message: "Couldn't delete user", error)
        }
    }
}

protocol TodoControllerDelegate {
    func presentError(message: String, _ err: Error?)
}
