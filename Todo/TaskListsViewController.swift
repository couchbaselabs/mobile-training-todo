//
//  TaskListsViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit

class TaskListsViewController: UITableViewController, UISearchResultsUpdating {
    var searchController: UISearchController!
    
    var username: String!
    var database: CBLDatabase!
    
    var listsLiveQuery: CBLLiveQuery!
    var listRows : [CBLQueryRow]?
    
    var incompTasksCountsLiveQuery: CBLLiveQuery!
    var incompTasksCounts : [String : Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Navigation bar:
        if !kLoginFlowEnabled {
            // Remove logout button:
            self.navigationItem.leftBarButtonItem = nil
        }
        
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
    }

    deinit {
        if listsLiveQuery != nil {
            listsLiveQuery.removeObserver(self, forKeyPath: "rows")
            listsLiveQuery.stop()
        }
        
        if incompTasksCountsLiveQuery != nil {
            incompTasksCountsLiveQuery.removeObserver(self, forKeyPath: "rows")
            incompTasksCountsLiveQuery.stop()
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? UITabBarController {
            let selectedList = listRows![self.tableView.indexPathForSelectedRow!.row].document
            
            let tasksController = tabBarController.viewControllers![0] as! TasksViewController
            tasksController.taskList = selectedList
            
            let usersController = tabBarController.viewControllers![1] as! UsersViewController
            usersController.taskList = selectedList
        }
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? NSObject == listsLiveQuery {
            reloadTaskLists()
        } else if object as? NSObject == incompTasksCountsLiveQuery {
            reloadIncompleteTasksCounts()
        }
    }

    // MARK: - UITableViewController
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listRows?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        
        let row = listRows![indexPath.row] as CBLQueryRow
        
        cell.textLabel?.text = row.value(forKey: "key") as? String
        
        let incompleteCount = incompTasksCounts?[row.documentID!] ?? 0
        cell.detailTextLabel?.text = incompleteCount > 0 ? "\(incompleteCount)" : ""
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath)
        -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Delete list document:
            let doc = self.listRows![indexPath.row].document!
            self.deleteTaskList(list: doc)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        
        let update = UITableViewRowAction(style: .normal, title: "Edit") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Display update list dialog:
            let doc = self.listRows![indexPath.row].document!
            
            Ui.showTextInputDialog(
                onController: self,
                withTitle: "Edit List",
                withMessage:  nil,
                withTextFieldConfig: { textField in
                    textField.placeholder = "List name"
                    textField.text = doc["name"] as? String
                    textField.autocapitalizationType = .words
                },
                onOk: { (name) -> Void in
                    self.updateTaskList(list: doc, withName: name)
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
            listsLiveQuery.startKey = text
            listsLiveQuery.prefixMatchLevel = 1
        } else {
            listsLiveQuery.startKey = nil
            listsLiveQuery.prefixMatchLevel = 0
        }
        listsLiveQuery.endKey = listsLiveQuery.startKey
        listsLiveQuery.queryOptionsChanged()
    }
    
    // MARK: - Action
    @IBAction func addAction(sender: AnyObject) {
        Ui.showTextInputDialog(
            onController: self,
            withTitle: "New Task List",
            withMessage:  nil,
            withTextFieldConfig: { textField in
                textField.placeholder = "List name"
                textField.autocapitalizationType = .words
            },
            onOk: { name in
                self.createTaskList(name: name)
            }
        )
    }
    
    @IBAction func logoutAction(sender: AnyObject) {
        let app = UIApplication.shared.delegate as! AppDelegate
        app.logout()
    }

    // MARK: - Database

    func setupViewAndQuery() {
        let listsView = database.viewNamed("list/listsByName")
        if listsView.mapBlock == nil {
            listsView.setMapBlock({ (doc, emit) in
                if let type: String = doc["type"] as? String, let name = doc["name"]
                    , type == "task-list" {
                        emit(name, nil)
                }
            }, version: "1.0")
        }

        listsLiveQuery = listsView.createQuery().asLive()
        listsLiveQuery.addObserver(self, forKeyPath: "rows", options: .new, context: nil)
        listsLiveQuery.start()
        
        let incompTasksCountView = database.viewNamed("list/incompleteTasksCount")
        if incompTasksCountView.mapBlock == nil {
            incompTasksCountView.setMapBlock({ (doc, emit) in
                if let type: String = doc["type"] as? String , type == "task" {
                    if let list = doc["taskList"] as? [String: AnyObject], let listId = list["id"],
                        let complete = doc["complete"] as? Bool , !complete {
                        emit(listId, nil)
                    }
                }
                }, reduce: { (keys, values, reredeuce) in
                return values.count
            }, version: "1.0")
        }
        
        incompTasksCountsLiveQuery = incompTasksCountView.createQuery().asLive()
        incompTasksCountsLiveQuery.groupLevel = 1
        incompTasksCountsLiveQuery.addObserver(self, forKeyPath: "rows", options: .new, context: nil)
        incompTasksCountsLiveQuery.start()
    }

    func reloadTaskLists() {
        listRows = listsLiveQuery.rows?.allObjects as? [CBLQueryRow] ?? nil
        tableView.reloadData()
    }
    
    func reloadIncompleteTasksCounts() {
        var counts : [String : Int] = [:]
        let rows = incompTasksCountsLiveQuery.rows
        while let row = rows?.nextRow() {
            if let listId = row.value(forKey: "key") as? String, let count = row.value as? Int {
                counts[listId] = count
            }
        }
        incompTasksCounts = counts
        tableView.reloadData()
    }

    func createTaskList(name: String) {
        let properties: [String : Any] = [
            "type": "task-list",
            "name": name,
            "owner": username
        ]

        let docId = username + "." + NSUUID().uuidString
        guard let doc = database.document(withID: docId) else {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't save task list")
            return
        }

        do {
            try doc.putProperties(properties)
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't save task list", withError: error)
        }
    }
    
    func updateTaskList(list: CBLDocument, withName name: String) {
        do {
            try list.update { newRev in
                newRev["name"] = name
                return true
            }
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't update task list", withError: error)
        }
    }
    
    func deleteTaskList(list: CBLDocument) {
        do {
            try list.delete()
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't delete task list", withError: error)
        }
    }
}
