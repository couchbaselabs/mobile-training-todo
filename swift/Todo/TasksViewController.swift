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
    
    var database: Database!
    var taskList: Document!
    var taskQuery: Query!
    var searchQuery: Query!
    var taskRows : [QueryRow]?
    var taskForImage: Document?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Get database and username:
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load tasks:
        reload()
    }
    
    // MARK: - Database
    
    func reload() {
        if (taskQuery == nil) {
            let listID = taskList.documentID
            taskQuery = database.createQuery(
                where: "type == 'task' AND taskList.id == '\(listID)'",
                orderBy: ["createdAt", "task"])
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
        let doc = database.document()
        doc["type"] = "task";
        doc["taskList"] = ["id": taskList.documentID, "owner": taskList.property("owner")];
        doc["createdAt"] = Date()
        doc["task"] = task;
        doc["complete"] = false
        
        do {
            try doc.save()
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task", error: error)
        }
    }
    
    func updateTask(task: Document, withTitle title: String) {
        do {
            task["task"] = title
            try task.save()
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func updateTask(task: Document, withComplete complete: Bool) {
        do {
            task["complete"] = complete
            try task.save()
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
            task["image"] = blob
            try task.save()
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func deleteTask(task: Document) {
        do {
            try task.delete()
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete task", error: error)
        }
    }
    
    func searchTask(task: String) {
        if (searchQuery == nil) {
            let listID = taskList.documentID
            let w = "type == 'task' AND taskList.id == '\(listID)' AND task contains[c] $NAME"
            searchQuery = database.createQuery(where: w, orderBy: ["createdAt", "task"])
        }
        
        do {
            searchQuery.parameters = ["NAME": task]
            let rows = try searchQuery.run()
            taskRows = Array(rows)
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error searching tasks: %@", error)
        }
    }
    
    // MARK: - Action
    
    @IBAction func addAction(_ sender: Any) {
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
        cell.taskLabel.text = doc["task"]
        
        let complete: Bool = doc["complete"]
        cell.accessoryType = complete ? .checkmark : .none
        
        if let imageBlob = doc.property("image") as? Blob {
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
        if let imageBlob = doc.property("image") as? Blob, let d = imageBlob.digest, d == digest {
            let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
            cell.taskImage = image
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let doc = taskRows![indexPath.row].document
        let complete: Bool = !doc["complete"]
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
                text.text = document["task"]
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
