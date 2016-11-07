//
//  TasksViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit

class TasksViewController: UITableViewController, UISearchResultsUpdating,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var searchController: UISearchController!
    
    var username: String!
    var database: CBLDatabase!
    var taskList: CBLDocument!
    var tasksLiveQuery: CBLLiveQuery!
    var taskRows : [CBLQueryRow]?
    var taskForImage: CBLDocument?
    var dbChangeObserver: AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Get database and username:
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database
        username = Session.username
        
        // Setup view and query:
        setupViewAndQuery()
        
        // Display or hide users:
        displayOrHideUsers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Setup navigation bar:
        self.tabBarController?.title = taskList["name"] as? String
        self.tabBarController?.navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction(sender:)))
    }
    
    deinit {
        if tasksLiveQuery != nil {
            tasksLiveQuery.removeObserver(self, forKeyPath: "rows")
            tasksLiveQuery.stop()
        }
        
        if dbChangeObserver != nil {
            NotificationCenter.default.removeObserver(dbChangeObserver!)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTaskImage" {
            let navController = segue.destination as! UINavigationController
            let controller = navController.topViewController as! TaskImageViewController
            controller.task = taskForImage
            taskForImage = nil
        }
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? NSObject == tasksLiveQuery {
            reloadTasks()
        }
    }
    
    // MARK: - UITableViewController
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskRows?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as! TaskTableViewCell
        
        let doc = taskRows![indexPath.row].document!
        cell.taskLabel.text = doc["task"] as? String
        
        let complete = doc["complete"] as? Bool ?? false
        cell.accessoryType = complete ? .checkmark : .none
        
        let rev = doc.currentRevision
        if let attachment = rev?.attachmentNamed("image"), let data = attachment.content {
            let digest = attachment.metadata["digest"] as! String
            let scale = UIScreen.main.scale
            let thumbnail = Image.square(image: UIImage(data: data, scale: scale), withSize: 44.0,
                                         withCacheName: digest, onComplete: { (thumbnail) -> Void in
                                            self.updateImage(image: thumbnail, withDigest: digest, atIndexPath: indexPath)
            })
            cell.taskImage = thumbnail
            cell.taskImageAction = {
                self.taskForImage = doc
                self.performSegue(withIdentifier: "showTaskImage", sender: self)
            }
        } else {
            cell.taskImage = nil
            cell.taskImageAction = {
                self.taskForImage = doc
                Ui.showImageActionSheet(onController: self, withImagePickerDelegate: self)
            }
        }
        return cell
    }
    
    func updateImage(image: UIImage?, withDigest digest: String, atIndexPath indexPath: IndexPath) {
        guard let rows = self.taskRows, rows.count > indexPath.row else {
            return
        }
        
        let rev = rows[indexPath.row].document!.currentRevision
        if let revDigest = rev?.attachmentNamed("image")?.metadata["digest"] as? String, digest == revDigest {
                let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
                cell.taskImage = image
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let doc = taskRows![indexPath.row].document!
        var complete = doc["complete"] as? Bool ?? false
        complete = !complete
        
        updateTask(task: doc, withComplete: complete)
        
        // Optimistically update the UI:
        let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
        cell.accessoryType = complete ? .checkmark : .none
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Delete list document:
            let doc = self.taskRows![indexPath.row].document!
            self.deleteTask(task: doc)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        
        let update = UITableViewRowAction(style: .normal, title: "Edit") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Display update list dialog:
            let document = self.taskRows![indexPath.row].document!
            
            Ui.showTextInputDialog(
                onController: self,
                withTitle: "Edit Task",
                withMessage:  nil,
                withTextFieldConfig: { textField in
                    textField.placeholder = "Task"
                    textField.text = document["task"] as? String
                    textField.autocapitalizationType = .sentences
                },
                onOk: { task in
                    self.updateTask(task: document, withTitle: task)
                }
            )
        }
        update.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        
        return [delete, update]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        if !text.isEmpty {
            tasksLiveQuery.postFilter = NSPredicate(format: "key2 CONTAINS[cd] %@", text)
        } else {
            tasksLiveQuery.postFilter = nil
        }
        tasksLiveQuery.queryOptionsChanged()
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let task = taskForImage {
            updateTask(task: task, withImage: info["UIImagePickerControllerOriginalImage"] as! UIImage)
            self.taskForImage = nil
        }
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Action
    
    func addAction(sender: AnyObject) {
        Ui.showTextInputDialog(
            onController: self,
            withTitle: "New Task",
            withMessage: nil,
            withTextFieldConfig: { textField in
                textField.placeholder = "Task"
                textField.autocapitalizationType = .sentences
            },
            onOk: { task in
                _ = self.createTask(task: task)
            }
        )
    }
    
    // MARK: - Database
    
    func setupViewAndQuery() {
        let view = database.viewNamed("tasksByCreatedAt")
        if view.mapBlock == nil {
            view.setMapBlock({ (doc, emit) in
                if let type = doc["type"] as? String,
                   let listId = (doc["taskList"] as? [String: Any])?["id"],
                   let createdAt = doc["createdAt"],
                   let task = doc["task"],
                   type == "task" {
                    emit([listId, createdAt, task], nil)
                }
            }, version: "1.0")
        }

        tasksLiveQuery = view.createQuery().asLive()
        tasksLiveQuery.startKey = [taskList.documentID]
        tasksLiveQuery.endKey = [taskList.documentID]
        tasksLiveQuery.prefixMatchLevel = 1
        tasksLiveQuery.descending = false
        
        tasksLiveQuery.addObserver(self, forKeyPath: "rows", options: .new, context: nil)
        tasksLiveQuery.start()
    }
    
    func reloadTasks() {
        taskRows = tasksLiveQuery.rows?.allObjects as? [CBLQueryRow] ?? nil
        tableView.reloadData()
    }
    
    func createTask(task: String) -> CBLSavedRevision? {
        let taskListInfo = [
            "id": taskList.documentID,
            "owner": taskList["owner"]!
        ]
        
        let properties: Dictionary<String, Any> = [
            "type": "task",
            "taskList": taskListInfo,
            "createdAt": CBLJSON.jsonObject(with: Date()),
            "task": task,
            "complete": false
        ]
        
        let doc = database.createDocument()
        do {
            return try doc.putProperties(properties)
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't save task", withError: error)
            return nil
        }
    }
    
    func updateTask(task: CBLDocument, withTitle title: String) {
        do {
            try task.update { newRev in
                newRev["task"] = title
                return true
            }
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't update task", withError: error)
        }
    }
    
    func updateTask(task: CBLDocument, withComplete complete: Bool) {
        do {
            try task.update { newRev in
                newRev["complete"] = complete
                return true
            }
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't update complete status", withError: error)
        }
    }
    
    func updateTask(task: CBLDocument, withImage image: UIImage) {
        let newRev = task.newRevision()
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Invalid image format")
            return
        }
        newRev.setAttachmentNamed("image", withContentType: "image/jpg", content: imageData)
        do {
            try newRev.save()
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't add image", withError: error)
        }
    }
    
    func deleteTask(task: CBLDocument) {
        do {
            try task.delete()
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't delete task", withError: error)
        }
    }
    
    func displayOrHideUsers() {
        var display = false
        let moderatorDocId = "moderator." + username
        if username == taskList["owner"] as? String {
            display = true
        } else {
            display = (database.existingDocument(withID: moderatorDocId) != nil)
        }
        Ui.displayOrHideTabbar(onController: self, withDisplay: display)
        
        if dbChangeObserver == nil {
            dbChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.cblDatabaseChange, object: database, queue: nil) { note in
                // Review: Can optimize this by executing in the background dispatch queue:
                if let changes = note.userInfo!["changes"] as? [CBLDatabaseChange] {
                    for change in changes {
                        if change.source == nil {
                            return
                        }
                        if change.documentID == moderatorDocId {
                            self.displayOrHideUsers()
                            return
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Conflicts
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            // TRAINING: Create task conflict (for development only)
            let savedRevision = createTask(task: "Text")
            let newRev1 = savedRevision?.createRevision()
            let propsRev1 = newRev1?.properties
            propsRev1?.setValue("Text Changed", forKey: "task")
            let newRev2 = savedRevision?.createRevision()
            let propsRev2 = newRev2?.properties
            propsRev2?.setValue(true, forKey: "complete")
            do {
                try newRev1?.saveAllowingConflict()
                try newRev2?.saveAllowingConflict()
            } catch let error as NSError {
                NSLog("Could not save revisions %@", error)
            }
        }
    }

}
