//
//  TaskListsViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLite

class ListsViewController: UITableViewController, UISearchResultsUpdating {
    var searchController: UISearchController!
    
    var database: CBLDatabase!
    var username: String!
    
    var listQuery: CBLQuery!
    var searchQuery: CBLQuery!
    var listRows : [CBLQueryRow]?
    
    var incompTasksCountsQuery: CBLQuery!
    var incompTasksCounts: [String:Int] = [:]
    var shouldUpdateIncompTasksCount: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Get database:
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database
        
        // Get username:
        username = app.username
        
        reload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (shouldUpdateIncompTasksCount) {
            updateIncompleteTasksCounts()
        }
    }
    
    // MARK: - Database
    
    func reload() {
        if (listQuery == nil) {
            listQuery = database.createQueryWhere("type == 'task-list'")
            listQuery.orderBy = ["name"]
        }
        
        do {
            let rows = try listQuery.run()
            listRows = rows.allObjects as? [CBLQueryRow]
            
            updateIncompleteTasksCounts()
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error querying task list: %@", error)
        }
    }
    
    func updateIncompleteTasksCounts() {
        shouldUpdateIncompTasksCount = false;
        
        if (incompTasksCountsQuery == nil) {
            incompTasksCountsQuery = database.createQueryWhere("type == 'task' AND complete == false")
            incompTasksCountsQuery.groupBy = ["taskList.id"]
            incompTasksCountsQuery.returning = ["taskList.id", "count(1)"]
        }
        
        do {
            incompTasksCounts.removeAll()
            let rows = try incompTasksCountsQuery.run()
            while let row = rows.nextObject() as? CBLQueryRow {
                incompTasksCounts[row.string(at: 0)!] = row.integer(at: 1);
            }
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error querying incomplete tasks counts: %@", error)
        }
    }
    
    func createTaskList(name: String) {
        let docId = username + "." + NSUUID().uuidString
        let doc = database.document(withID: docId)
        doc["type"] = "task-list"
        doc["name"] = name
        doc["owner"] = username
        
        do {
            try doc.save()
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't save task list", error: error)
        }
    }
    
    func updateTaskList(list: CBLDocument, withName name: String) {
        list["name"] = name
        do {
            try list.save()
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update task list", error: error)
        }
    }
    
    func deleteTaskList(list: CBLDocument) {
        do {
            try list.delete()
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete task list", error: error)
        }
    }
    
    func searchTaskList(name: String) {
        if (searchQuery == nil) {
            searchQuery = database.createQueryWhere("type == 'task-list' AND name contains[c] $NAME")
            searchQuery.orderBy = ["name"]
        }
        
        do {
            searchQuery.parameters = ["NAME": name]
            let rows = try searchQuery.run()
            listRows = rows.allObjects as? [CBLQueryRow]
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
   
    // MARK: - UITableViewController
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listRows?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        let row = listRows![indexPath.row] as CBLQueryRow
        cell.textLabel?.text = row.document.string(forKey: "name")
        cell.detailTextLabel?.text = nil
        
        let count = incompTasksCounts[row.documentID] ?? 0
        cell.detailTextLabel?.text = count > 0 ? "\(count)" : ""
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            
            // Delete list document:
            let doc = self.listRows![indexPath.row].document
            self.deleteTaskList(list: doc)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        
        let update = UITableViewRowAction(style: .normal, title: "Edit") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            
            // Display update list dialog:
            let doc = self.listRows![indexPath.row].document
            
            // Display update list dialog:
            Ui.showTextInput(on: self, title: "Edit List", message:  nil, textFieldConfig: { text in
                text.placeholder = "List name"
                text.text = doc["name"] as? String
                text.autocapitalizationType = .words
            }, onOk: { (name) -> Void in
                self.updateTaskList(list: doc, withName: name)
            })
        }
        update.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        
        return [delete, update]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResults(for searchController: UISearchController) {
        if let name = searchController.searchBar.text, !name.isEmpty {
            searchTaskList(name: name)
        } else {
            reload()
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let row = listRows![self.tableView.indexPathForSelectedRow!.row]
        let controller = segue.destination as! TasksViewController
        controller.taskList = row.document
        shouldUpdateIncompTasksCount = true
    }
}
