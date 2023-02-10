//
// ListViewController.swift
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

class ListsViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {    
    var searchController: UISearchController!
    
    var username: String!
    
    var listQuery: Query!
    var listRows : [Result]?
    
    var searchQuery: Query!
    var inSearch = false;
    var searchRows : [Result]?
    
    var incompTasksCountsQuery: Query!
    var incompTasksCounts: [String:Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Get username:
        username = Session.username
        
        reload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.leftBarButtonItem?.isEnabled = true
    }
    
    func updateReplicatorStatus(_ level: Replicator.ActivityLevel) {
        DispatchQueue.main.async {
            var textAttributes: [NSAttributedStringKey: UIColor]
            switch level {
            case .connecting, .busy:
                textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.yellow]
            case .idle:
                textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]
            case .offline:
                textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.orange]
            case .stopped:
                textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.red]
            }
            self.navigationController?.navigationBar.titleTextAttributes = textAttributes
        }
    }
    
    // MARK: - Database
    
    func reload() {
        if (listQuery == nil) {
            // Task List:
            listQuery = try! DB.shared.getTaskListsQuery()
            listQuery.addChangeListener({ (change) in
                if let error = change.error {
                    NSLog("Error querying task list: %@", error.localizedDescription)
                }
                self.listRows = change.results != nil ? Array(change.results!) : nil
                self.tableView.reloadData()
            })
            
            // Incomplete tasks count:
            incompTasksCountsQuery = try! DB.shared.getIncompletedTasksCountsQuery()
            incompTasksCountsQuery.addChangeListener({ (change) in
                if change.error == nil {
                    self.updateIncompleteTasksCounts(change.results!)
                } else {
                    NSLog("Error querying incomplete task counts: %@", change.error!.localizedDescription)
                }
            })
        }
    }
    
    func updateIncompleteTasksCounts(_ rows: ResultSet) {
        incompTasksCounts.removeAll()
        for row in rows {
            incompTasksCounts[row.string(at: 0)!] = row.int(at: 1)
        }
        tableView.reloadData()
    }
    
    func createTaskList(name: String) {
        do {
            try DB.shared.createTaskList(name: name)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task list", error: error)
        }
    }
    
    func updateTaskList(listID: String, name: String) {
        do {
            try DB.shared.updateTaskList(listID: listID, name: name)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task list", error: error)
        }
    }
    
    func deleteTaskList(listID: String) {
        do {
            try DB.shared.deleteTaskList(listID: listID)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete task list", error: error)
        }
    }
    
    func searchTaskList(name: String) {
        do {
            let rs = try DB.shared.getTaskListsByName(name: name)
            searchRows = Array(rs)
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error searching task list: %@", error)
        }
    }
    
    // MARK: - Action
    
    @IBAction func addAction(sender: AnyObject) {
        Ui.showTextInput(on: self, title: "New Task List", message:  nil, textFieldConfig: { text in
            text.placeholder = "List name"
            text.autocapitalizationType = .words
        }, onOk: { name in
            self.createTaskList(name: name)
        })
    }
    
    @IBAction func logOut(sender: Any) {
        let alert = UIAlertController(title: nil, message: nil,
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Close Database", style: .default) { _ in
            let app = UIApplication.shared.delegate as! AppDelegate
            app.logout(method: .closeDatabase)
        })
        
        alert.addAction(UIAlertAction(title: "Delete Database", style: .default) { _ in
            let app = UIApplication.shared.delegate as! AppDelegate
            app.logout(method: .deleteDatabase)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        
        self.present(alert, animated: true, completion: nil)
    }
   
    // MARK: - UITableViewController
    
    var data: [Result]? {
        return inSearch ? searchRows : listRows
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        let row = self.data![indexPath.row]
        cell.textLabel?.text = row.string(at: 1)
        cell.detailTextLabel?.text = nil
        
        let docID = row.string(at: 0)!
        let count = incompTasksCounts[docID] ?? 0
        cell.detailTextLabel?.text = count > 0 ? "\(count)" : ""
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let row = self.data![indexPath.row]
        let id = row.string(at: 0)!
        let name = row.string(at: 1)!
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            
            // Delete list document:
            self.deleteTaskList(listID: id)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        
        let update = UITableViewRowAction(style: .normal, title: "Edit") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            
            // Display update list dialog:
            Ui.showTextInput(on: self, title: "Edit List", message:  nil, textFieldConfig: { text in
                text.placeholder = "List name"
                text.autocapitalizationType = .words
                text.text = name
            }, onOk: { (newName) -> Void in
                self.updateTaskList(listID: id, name: newName)
            })
        }
        update.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        
        let log = UITableViewRowAction(style: .normal, title: "Log") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            try! logTaskList(id: id)
        }
        
        return [delete, update, log]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResults(for searchController: UISearchController) {
        if let name = searchController.searchBar.text, !name.isEmpty {
            inSearch = true
            searchTaskList(name: name)
        } else {
            searchBarCancelButtonClicked(searchController.searchBar)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        inSearch = false
        searchRows = nil
        self.tableView.reloadData()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? UITabBarController {
            let row = self.data![self.tableView.indexPathForSelectedRow!.row]
            let docID = row.string(at: 0)!
            
            // TODO: handle error
            guard let taskList = try? DB.shared.getTaskListByID(id: docID) else {
                return
            }
            
            let tasksController = tabBarController.viewControllers![0] as! TasksViewController
            tasksController.taskList = taskList
            
            let usersController = tabBarController.viewControllers![1] as! UsersViewController
            usersController.taskList = taskList
        }
    }
}
