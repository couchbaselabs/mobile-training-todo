//
//  TasksViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class TasksViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate,
                           UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    var searchController: UISearchController!
    
    var username: String!
    var database: Database!
    var taskList: Document!
    
    var taskQuery: Query!
    var taskRows : [Result]?
    
    var searchQuery: Query!
    var inSearch = false;
    var searchRows : [Result]?
    
    var taskIDForImage: String?
    var dbChangeListener: ListenerToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
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
            taskQuery = QueryBuilder
                .select(S_ID, S_TASK, S_COMPLETE, S_IMAGE)
                .from(DataSource.database(database))
                .where(TYPE.equalTo(Expression.string("task")).and(TASK_LIST_ID.equalTo(Expression.string(taskList.id))))
                .orderBy(Ordering.expression(CREATED_AT), Ordering.expression(TASK))
            
            taskQuery.addChangeListener({ (change) in
                if let error = change.error {
                    NSLog("Error quering tasks: %@", error.localizedDescription)
                }
                self.taskRows = change.results != nil ? Array(change.results!) : nil
                self.tableView.reloadData()
            })
        }
    }
    
    func createTask(task: String) {
        let doc = MutableDocument()
        doc.setValue("task", forKey: "type")
        
        let taskListInfo = ["id": taskList.id, "owner": taskList.string(forKey: "owner")]
        doc.setValue(taskListInfo, forKey: "taskList")
        doc.setValue(Date(), forKey: "createdAt")
        doc.setValue(task, forKey: "task")
        doc.setValue(false, forKey: "complete")
        
        do {
            try database.saveDocument(doc)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task", error: error)
        }
    }
    
    func createTaskWithDeltaSync(task: String) {
        let doc = MutableDocument()
        doc.setValue("task", forKey: "type")
        
        let taskListInfo = ["id": taskList.id, "owner": taskList.string(forKey: "owner")]
        doc.setValue(taskListInfo, forKey: "taskList")
        doc.setValue(Date(), forKey: "createdAt")
        doc.setValue(task, forKey: "task")
        doc.setValue(false, forKey: "complete")
        
        var value = "12345678901234567890123456789012345678901234567890" // 50B
        for _ in 0..<10000 {
            value.append("12345678901234567890123456789012345678901234567890")
        }
        doc.setValue(value, forKey: "delta-sync-payload")
        do {
            try database.saveDocument(doc)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task", error: error)
        }
    }
    
    func updateTask(taskID: String, withTitle title: String) {
        do {
            let task = database.document(withID: taskID)!.toMutable()
            task.setValue(title, forKey: "task")
            try database.saveDocument(task)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func updateTask(taskID: String, withComplete complete: Bool) {
        do {
            let task = database.document(withID: taskID)!.toMutable()
            task.setValue(complete, forKey: "complete")
            try database.saveDocument(task)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func updateTask(taskID: String, withImage image: UIImage) {
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            Ui.showError(on: self, message: "Invalid image format")
            return
        }
        
        do {
            let task = database.document(withID: taskID)!.toMutable()
            let blob = Blob(contentType: "image/jpeg", data: imageData)
            task.setValue(blob, forKey: "image")
            try database.saveDocument(task)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task", error: error)
        }
    }
    
    func deleteTask(taskID: String) {
        do {
            let task = database.document(withID: taskID)!
            try database.deleteDocument(task)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete task", error: error)
        }
    }
    
    func searchTask(task: String) {
        searchQuery = QueryBuilder
            .select(S_ID, S_TASK, S_COMPLETE, S_IMAGE)
            .from(DataSource.database(database))
            .where(TYPE.equalTo(Expression.string("task"))
                .and(TASK_LIST_ID.equalTo(Expression.string(taskList.id)))
                .and(TASK.like(Expression.string("%\(task)%"))))
            .orderBy(Ordering.expression(CREATED_AT), Ordering.expression(TASK))
        
        do {
            let rows = try searchQuery.execute()
            searchRows = Array(rows)
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
            display = database.document(withID: moderatorDocId) != nil
        }
        Ui.displayOrHideTabbar(on: self, display: display)
        
        if dbChangeListener == nil {
            dbChangeListener = database.addChangeListener({ [weak self] (change) in
                guard let strongSelf = self else { return }
                for docId in change.documentIDs {
                    if docId == moderatorDocId {
                        strongSelf.displayOrHideUsers()
                        break
                    }
                }
            })
        }
    }
    
    // MARK: - Action
    
    @objc func addAction(sender: Any) {
        if kQEFeaturesEnabled {
            showQEActions()
        } else {
            showCreateTaskInput()
        }
    }
    
    func showCreateTaskInput() {
        Ui.showTextInput(on: self, title: "New Task", message: nil, textFieldConfig: { text in
            text.placeholder = "Task"
            text.autocapitalizationType = .sentences
        }, onOk: { task in
            self.createTask(task: task)
        })
    }
    
    func showCreateTaskInputForDeltaSync() {
        Ui.showTextInput(on: self, title: "New Task(DeltaSync)", message: nil, textFieldConfig: { text in
            text.placeholder = "Task"
            text.autocapitalizationType = .sentences
        }, onOk: { task in
            self.createTaskWithDeltaSync(task: task)
        })
    }
    
    func showQEActions() {
        let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actions.addAction(UIAlertAction(title: "New Task", style: .default) { _ in
            self.showCreateTaskInput()
        })
        
        actions.addAction(UIAlertAction(title: "New Task(DeltaSync)", style: .default) { _ in
            self.showCreateTaskInputForDeltaSync()
        })
        
        actions.addAction(UIAlertAction(title: "Generate Tasks", style: .default) { _ in
            QE.generateTasks(database: self.database, taskList: self.taskList, numbers: 50, includesPhoto: true)
        })
        
        actions.addAction(UIAlertAction(title: "Generate No Photo Tasks", style: .default) { _ in
            QE.generateTasks(database: self.database, taskList: self.taskList, numbers: 50, includesPhoto: false)
        })
        
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        
        self.present(actions, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewController
    
    var data: [Result]? {
        return inSearch ? searchRows : taskRows
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as! TaskTableViewCell
        
        let result = self.data![indexPath.row]
        let docID = result.string(at: 0)!
        cell.taskLabel.text = result.string(at: 1)!
        
        let complete: Bool = result.boolean(at: 2)
        cell.accessoryType = complete ? .checkmark : .none
        
        if let imageBlob = result.blob(at: 3) {
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
                self.taskIDForImage = docID
                self.performSegue(withIdentifier: "showTaskImage", sender: self)
            }
        } else {
            cell.taskImage = nil
            cell.taskImageAction = {
                self.taskIDForImage = docID
                Ui.showImageActionSheet(on: self, imagePickerDelegate: self)
            }
        }
        
        return cell
    }
    
    func updateImage(image: UIImage?, withDigest digest: String, atIndexPath indexPath: IndexPath) {
        guard let rows = self.taskRows, rows.count > indexPath.row else {
            return
        }
        
        let row = self.data![indexPath.row]
        let docID = row.string(at: 0)!
        let doc = database.document(withID: docID)!
        
        if let imageBlob = doc.blob(forKey: "image"), let d = imageBlob.digest, d == digest {
            let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
            cell.taskImage = image
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = self.data![indexPath.row]
        let docID = row.string(at: 0)!
        let doc = database.document(withID: docID)!
        
        let complete: Bool = !doc.boolean(forKey: "complete")
        updateTask(taskID: docID, withComplete: complete)
        
        // Optimistically update the UI:
        let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
        cell.accessoryType = complete ? .checkmark : .none
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let row = self.data![indexPath.row]
        let docID = row.string(at: 0)!
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Delete list document:
            self.deleteTask(taskID: docID)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        
        let update = UITableViewRowAction(style: .normal, title: "Edit") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Display update list dialog:
            Ui.showTextInput(on: self, title: "Edit Task", message:  nil, textFieldConfig: { text in
                let doc = self.database.document(withID: docID)!
                text.placeholder = "Task"
                text.text = doc.string(forKey: "task")
                text.autocapitalizationType = .sentences
            }, onOk: { task in
                self.updateTask(taskID: docID, withTitle: task)
            })
        }
        update.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        
        let log = UITableViewRowAction(style: .normal, title: "Log") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Get doc:
            let doc = self.database.document(withID: docID)!
            logTask(doc: doc)
        }
        
        return [delete, update, log]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResults(for searchController: UISearchController) {
        if let task = searchController.searchBar.text, !task.isEmpty {
            inSearch = true
            searchTask(task: task)
        } else {
            searchBarCancelButtonClicked(searchController.searchBar)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        inSearch = false
        searchRows = nil
        self.tableView.reloadData()
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let taskID = taskIDForImage {
            updateTask(taskID: taskID, withImage: info["UIImagePickerControllerOriginalImage"] as! UIImage)
            self.taskIDForImage = nil
        }
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTaskImage" {
            let navController = segue.destination as! UINavigationController
            let controller = navController.topViewController as! TaskImageViewController
            controller.taskID = taskIDForImage
            taskIDForImage = nil
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        // Fix "... load the view of a view controller while it is deallocating" warning.
        searchController?.view.removeFromSuperview()
        // Remove change listener:
        database.removeChangeListener(withToken: dbChangeListener!)
    }
}

