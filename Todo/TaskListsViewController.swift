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
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let tabBarController = segue.destinationViewController as? UITabBarController {
            let selectedList = listRows![self.tableView.indexPathForSelectedRow!.row].document
            
            let tasksController = tabBarController.viewControllers![0] as! TasksViewController
            tasksController.taskList = selectedList
            
            let usersController = tabBarController.viewControllers![1] as! UsersViewController
            usersController.taskList = selectedList
        }
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
        change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
            if object as? NSObject == listsLiveQuery {
                reloadTaskLists(listsLiveQuery.rows)
            } else if object as? NSObject == incompTasksCountsLiveQuery {
                reloadIncompleteTasksCounts(incompTasksCountsLiveQuery.rows)
            }
    }

    // MARK: - UITableViewController

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listRows?.count ?? 0
    }

    override func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("TaskListCell") as UITableViewCell!
            
            let doc = listRows![indexPath.row].document!
            cell.textLabel?.text = doc["name"] as? String
            
            let incompleteCount = incompTasksCounts?[doc.documentID] ?? 0
            cell.detailTextLabel?.text = incompleteCount > 0 ? "\(incompleteCount)" : ""
            
            return cell
    }
    
    override func tableView(tableView: UITableView,
        editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
            let delete = UITableViewRowAction(style: .Normal, title: "Delete") {
                (action, indexPath) -> Void in
                // Dismiss row actions:
                tableView.setEditing(false, animated: true)
                // Delete list document:
                let doc = self.listRows![indexPath.row].document!
                self.deleteTaskList(doc)
            }
            delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
            
            let update = UITableViewRowAction(style: .Normal, title: "Edit") {
                (action, indexPath) -> Void in
                // Dismiss row actions:
                tableView.setEditing(false, animated: true)
                // Display update list dialog:
                let doc = self.listRows![indexPath.row].document!
                
                Ui.showTextInputDialog(
                    onController: self,
                    withTitle: "Edit List",
                    withMessage:  nil,
                    withTextFieldConfig: { (textField) -> Void in
                        textField.placeholder = "List name"
                        textField.text = doc["name"] as? String
                        textField.autocapitalizationType = .Words
                    },
                    onOk: { (name) -> Void in
                        self.updateTaskList(doc, withName: name)
                    }
                )
            }
            update.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
            
            return [delete, update]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        let active = !text.isEmpty
        listsLiveQuery.startKey = active ? text : nil
        listsLiveQuery.endKey = listsLiveQuery.startKey
        listsLiveQuery.prefixMatchLevel = active ? 1 : 0
        listsLiveQuery.queryOptionsChanged()
    }
    
    // MARK: - Action
    @IBAction func addAction(sender: AnyObject) {
        Ui.showTextInputDialog(
            onController: self,
            withTitle: "New Task List",
            withMessage:  nil,
            withTextFieldConfig: { (textField) -> Void in
                textField.placeholder = "List name"
                textField.autocapitalizationType = .Words
            },
            onOk: { (name) -> Void in
                self.createTaskList(name)
            }
        )
    }
    
    @IBAction func logoutAction(sender: AnyObject) {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        app.logout()
    }

    // MARK: - Database

    func setupViewAndQuery() {
        let listsView = database.viewNamed("list/listsByName")
        if listsView.mapBlock == nil {
            listsView.setMapBlock({ (doc, emit) -> Void in
                if let type: String = doc["type"] as? String where type == "task-list" {
                    if let name = doc["name"] {
                        emit(name, nil)
                    }
                }
            }, version: "1.0")
        }

        listsLiveQuery = listsView.createQuery().asLiveQuery()
        listsLiveQuery.addObserver(self, forKeyPath: "rows", options: .New, context: nil)
        listsLiveQuery.start()
        
        let incompTasksCountView = database.viewNamed("list/incompleteTasksCount")
        if incompTasksCountView.mapBlock == nil {
            incompTasksCountView.setMapBlock({ (doc, emit) -> Void in
                if let type: String = doc["type"] as? String where type == "task" {
                    if let list = doc["taskList"] as? [String: AnyObject] {
                        if let listId = list["id"] {
                            if !(doc["complete"] as? Bool ?? false) {
                                emit(listId, nil)
                            }
                        }
                    }
                }
            }, reduceBlock: { (keys, values, reredeuce) -> AnyObject in
                return values.count
            }, version: "1.0")
        }
        
        incompTasksCountsLiveQuery = incompTasksCountView.createQuery().asLiveQuery()
        incompTasksCountsLiveQuery.groupLevel = 1
        incompTasksCountsLiveQuery.addObserver(self, forKeyPath: "rows", options: .New, context: nil)
        incompTasksCountsLiveQuery.start()
    }

    func reloadTaskLists(queryEnum: CBLQueryEnumerator?) {
        listRows = queryEnum?.allObjects as? [CBLQueryRow] ?? nil
        tableView.reloadData()
    }
    
    func reloadIncompleteTasksCounts(queryEnum: CBLQueryEnumerator?) {
        var counts : [String : Int] = [:]
        while let row = queryEnum?.nextRow() {
            if let listId = row.key as? String, count = row.value as? Int {
                counts[listId] = count
            }
        }
        incompTasksCounts = counts
        tableView.reloadData()
    }

    func createTaskList(name: String) {
        let properties: Dictionary<String, AnyObject> = [
            "type": "task-list",
            "name": name,
            "owner": username
        ]

        let docId = username + "." + NSUUID().UUIDString
        guard let doc = database.documentWithID(docId) else {
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
            try list.update { (newRev) -> Bool in
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
            try list.deleteDocument()
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't delete task list", withError: error)
        }
    }
}
