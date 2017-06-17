//
//  TasksViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class TasksViewController: UITableViewController, UISearchResultsUpdating,
UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var searchController: UISearchController!
    
    var username: String!
    var database: Database!
    var taskList: Document!
    var taskQuery: Query!
    var searchQuery: Query!
    var taskRows : [QueryRow]?
    var taskForImage: Document?
    var dbChangeObserver: AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Get database and username:
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database
        username = Session.username
        
        // Load data:
        reload()
        
        // Display or hide users:
        displayOrHideUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Setup navigation bar:
        self.tabBarController?.title = taskList.string(forKey: "name")
        self.tabBarController?.navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction(sender:)))
    }
    
    // MARK: - Database
    
    func reload() {
        if taskQuery == nil {
            taskQuery = Query
                .select()
                .from(DataSource.database(database))
                .where(
                    Expression.property("type").equalTo("task")
                        .and(Expression.property("taskList.id").equalTo(taskList.id)))
                .orderBy(OrderBy.property("createdAt"), OrderBy.property("task"))
        }
        
        do {
            let rows = try taskQuery.run()
            taskRows = Array(rows)
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error quering tasks: %@", error)
        }
    }
    
    func createTask(task: String) {
        let doc = Document()
        doc.set("task", forKey: "type")
        let taskListInfo = ["id": taskList.id, "owner": taskList.string(forKey: "owner")]
        doc.set(taskListInfo, forKey: "taskList")
        doc.set(Date(), forKey: "createdAt")
        doc.set(task, forKey: "task")
        doc.set(false, forKey: "complete")
        
        do {
            try database.save(doc)
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task", error: error)
        }
    }
    
    func updateTask(task: Document, withTitle title: String) {
        do {
            task.set(title, forKey: "task")
            try database.save(task)
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func updateTask(task: Document, withComplete complete: Bool) {
        do {
            task.set(complete, forKey: "complete")
            try database.save(task)
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func updateTask(task: Document, withImage image: UIImage) {
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            Ui.showError(on: self, message: "Invalid image format")
            return
        }
        
        do {
            let blob = Blob(contentType: "image/jpg", data: imageData)
            task.set(blob, forKey: "image")
            try database.save(task)
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func deleteTask(task: Document) {
        do {
            try database.delete(task)
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete task", error: error)
        }
    }
    
    func searchTask(task: String) {
        searchQuery = Query
            .select()
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo("task")
                    .and(Expression.property("taskList.id").equalTo(taskList.id))
                    .and(Expression.property("task").like("%\(task)%")))
            .orderBy(OrderBy.property("createdAt"), OrderBy.property("task"))
        
        do {
            let rows = try searchQuery.run()
            taskRows = Array(rows)
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error searching tasks: %@", error)
        }
    }
    
    // MARK: Users
    
    func displayOrHideUsers() {
        var display = false
        let moderatorDocId = "moderator." + username
        if username == taskList.string(forKey: "owner") {
            display = true
        } else {
            display = database.contains(moderatorDocId)
        }
        Ui.displayOrHideTabbar(on: self, display: display)
        
        if dbChangeObserver == nil {
            dbChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.DatabaseChange, object: database, queue: nil) { note in
                // Review: Can optimize this by executing in the background dispatch queue:
                if let change = note.userInfo![DatabaseChangesUserInfoKey] as? DatabaseChange {
                    for docId in change.documentIDs as! [String] {
                        if docId == moderatorDocId {
                            self.displayOrHideUsers()
                            break
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Action
    
    func addAction(sender: Any) {
        Ui.showTextInput(on: self, title: "New Task", message: nil, textFieldConfig: { text in
            text.placeholder = "Task"
            text.autocapitalizationType = .sentences
        }, onOk: { task in
            self.createTask(task: task)
        })
    }
    
    // MARK: - UITableViewController
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskRows?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as! TaskTableViewCell
        
        let doc = taskRows![indexPath.row].document
        cell.taskLabel.text = doc.string(forKey: "task")
        
        let complete: Bool = doc.boolean(forKey: "complete")
        cell.accessoryType = complete ? .checkmark : .none
        
        if let imageBlob = doc.blob(forKey: "image") {
            let digest = imageBlob.digest!
            let image = UIImage(data: imageBlob.content!, scale: UIScreen.main.scale)
            let thumbnail = Image.square(image: image,
                                         withSize: 44.0,
                                         withCacheName: digest,
                                         onComplete: { (thumbnail) -> Void in
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
                Ui.showImageActionSheet(on: self, imagePickerDelegate: self)
            }
        }
        
        return cell
    }
    
    func updateImage(image: UIImage?, withDigest digest: String, atIndexPath indexPath: IndexPath) {
        guard let rows = self.taskRows, rows.count > indexPath.row else {
            return
        }
        
        let doc = taskRows![indexPath.row].document
        if let imageBlob = doc.blob(forKey: "image"), let d = imageBlob.digest, d == digest {
            let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
            cell.taskImage = image
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let doc = taskRows![indexPath.row].document
        let complete: Bool = !doc.boolean(forKey: "complete")
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
            let doc = self.taskRows![indexPath.row].document
            self.deleteTask(task: doc)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        
        let update = UITableViewRowAction(style: .normal, title: "Edit") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Display update list dialog:
            let document = self.taskRows![indexPath.row].document
            
            Ui.showTextInput(on: self, title: "Edit Task", message:  nil, textFieldConfig: { text in
                text.placeholder = "Task"
                text.text = document.string(forKey: "task")
                text.autocapitalizationType = .sentences
            }, onOk: { task in
                self.updateTask(task: document, withTitle: task)
            })
        }
        update.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        
        return [delete, update]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResults(for searchController: UISearchController) {
        if let task = searchController.searchBar.text, !task.isEmpty {
            searchTask(task: task)
        } else {
            reload()
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let task = taskForImage {
            updateTask(task: task, withImage: info["UIImagePickerControllerOriginalImage"] as! UIImage)
            self.taskForImage = nil
        }
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
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
    
    // MARK: - Deinit
    
    deinit {
        // Fix "... load the view of a view controller while it is deallocating" warning.
        searchController?.view.removeFromSuperview()
    }
}

