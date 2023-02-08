//
// TasksViewController.swift
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

import UIKit
import CouchbaseLiteSwift

class TasksViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate,
                           UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    var searchController: UISearchController!
    
    var username: String!
    var database: Database!
    var taskList: Document?
    
    var taskQuery: Query!
    var taskRows : [Result]?
    
    var searchQuery: Query!
    var inSearch = false;
    var searchRows : [Result]?
    
    var selectedImageTaskID: String?
    var selectedImage: Blob?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Get current username:
        username = Session.username
        
        // Load data:
        reload()
        
        // Display or hide users:
        displayOrHideUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let taskList = self.taskList else { return }
        
        // Setup navigation bar:
        self.tabBarController?.title = taskList.string(forKey: "name")
        self.tabBarController?.navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction(sender:)))
    }
    
    // MARK: - Database
    
    func reload() {
        guard let taskList = self.taskList else { return }
        
        if taskQuery == nil {
            taskQuery = try! DB.shared.getTasksQuery(taskListID: taskList.id)
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
        do {
            guard let taskList = self.taskList else { return }
            try DB.shared.createTask(taskList: taskList, task: task)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task", error: error)
        }
    }
    
    func createTaskForTestingDeltaSync(task: String) {
        do {
            guard let taskList = self.taskList else { return }
            var extra = "12345678901234567890123456789012345678901234567890" // 50B
            for _ in 0..<10000 {
                extra.append("12345678901234567890123456789012345678901234567890")
            }
            try DB.shared.createTask(taskList: taskList, task: task, extra: extra)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task for testing delta sync", error: error)
        }
    }
    
    func updateTask(taskID: String, task: String) {
        do {
            try DB.shared.updateTask(taskID: taskID, task: task)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task with task", error: error)
        }
    }
    
    func updateTask(taskID: String, complete: Bool) {
        do {
            try DB.shared.updateTask(taskID: taskID, complete: complete)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task with complete", error: error)
        }
    }
    
    func updateTask(taskID: String, image: UIImage) {
        do {
            try DB.shared.updateTask(taskID: taskID, image: image)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task with image", error: error)
        }
    }
    
    func deleteTask(taskID: String) {
        do {
            try DB.shared.deleteTask(taskID: taskID)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete task", error: error)
        }
    }
    
    func searchTask(task: String) {
        do {
            guard let taskList = self.taskList else { return }
            let rs = try DB.shared.getTasksByTask(taskListID: taskList.id, task: task)
            searchRows = Array(rs)
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error searching tasks: %@", error)
        }
    }
    
    // MARK: Users
    
    func displayOrHideUsers() {
        let display = (username == taskList?.string(forKey: "owner"))
        Ui.displayOrHideTabbar(on: self, display: display)
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
            self.createTaskForTestingDeltaSync(task: task)
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
            do {
                try DB.shared.generateTasks(taskList: self.taskList!, numbers: 50, includesPhoto: true)
            } catch let error as NSError {
                NSLog("Error generating tasks: %@", error)
            }
        })
        
        actions.addAction(UIAlertAction(title: "Generate No Photo Tasks", style: .default) { _ in
            do {
                try DB.shared.generateTasks(taskList: self.taskList!, numbers: 50, includesPhoto: false)
            } catch let error as NSError {
                NSLog("Error generating tasks: %@", error)
            }
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
        
        let row = self.data![indexPath.row]
        let id = row.string(forKey: "id")!
        let task = row.string(forKey: "task")
        let complete = row.boolean(forKey: "complete")
        let image = row.blob(forKey: "image")
        
        cell.taskLabel.text = task
        cell.accessoryType = complete ? .checkmark : .none
        
        if let blob = image {
            let digest = blob.digest!
            let imageObj = UIImage(data: blob.content!, scale: UIScreen.main.scale)
            let thumbnail = Image.square(image: imageObj,
                                         withSize: 44.0,
                                         withCacheName: digest,
                                         onComplete: { (thumbnail) -> Void in
                                            self.updateImage(image: thumbnail, withDigest: digest, atIndexPath: indexPath)
            })
            cell.taskImage = thumbnail
            cell.taskImageAction = {
                self.selectedImageTaskID = id
                self.selectedImage = image
                self.performSegue(withIdentifier: "showTaskImage", sender: self)
            }
        } else {
            cell.taskImage = nil
            cell.taskImageAction = {
                self.selectedImageTaskID = id
                Ui.showImageActionSheet(on: self, imagePickerDelegate: self)
            }
        }
        
        return cell
    }
    
    func updateImage(image: UIImage?, withDigest digest: String, atIndexPath indexPath: IndexPath) {
        guard let rows = self.taskRows, rows.count > indexPath.row else { return }
        let row = self.data![indexPath.row]
        if let blob = row.blob(forKey: "image") {
            if digest == blob.digest {
                let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
                cell.taskImage = image
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = self.data![indexPath.row]
        let id = row.string(forKey: "id")!
        let complete = !row.boolean(forKey: "complete")
        updateTask(taskID: id, complete: complete)
        
        // Optimistically update the UI:
        let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell
        cell.accessoryType = complete ? .checkmark : .none
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let row = self.data![indexPath.row]
        let id = row.string(forKey: "id")!
        let task = row.string(forKey: "task")
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Delete list document:
            self.deleteTask(taskID: id)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        
        let update = UITableViewRowAction(style: .normal, title: "Edit") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Display update list dialog:
            Ui.showTextInput(on: self, title: "Edit Task", message:  nil, textFieldConfig: { text in
                text.placeholder = "Task"
                text.text = task
                text.autocapitalizationType = .sentences
            }, onOk: { newTask in
                self.updateTask(taskID: id, task: newTask)
            })
        }
        update.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        
        let log = UITableViewRowAction(style: .normal, title: "Log") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Get doc:
            // let doc = self.database.document(withID: docID)!
            // logTask(doc: doc)
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
        if let id = selectedImageTaskID {
            updateTask(taskID: id, image: info["UIImagePickerControllerOriginalImage"] as! UIImage)
            self.selectedImageTaskID = nil
        }
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTaskImage" {
            let navController = segue.destination as! UINavigationController
            let controller = navController.topViewController as! TaskImageViewController
            controller.taskID = selectedImageTaskID
            controller.imageBlob = selectedImage
            selectedImageTaskID = nil
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        // Fix "... load the view of a view controller while it is deallocating" warning.
        searchController?.view.removeFromSuperview()
    }
}
