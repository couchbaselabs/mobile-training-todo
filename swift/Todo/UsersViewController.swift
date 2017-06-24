//
//  UsersViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 6/16/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class UsersViewController: UITableViewController, UISearchResultsUpdating {
    var searchController: UISearchController!
    
    var username: String!
    var database: Database!
    var taskList: Document!
    var usersQuery: LiveQuery!
    var searchQuery: Query!
    var userRows : [QueryRow]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.dimsBackgroundDuringPresentation = false
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Get username and database:
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database
        username = Session.username
        
        // Load data:
        reload()
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
        if usersQuery == nil {
            usersQuery = Query
                .select()
                .from(DataSource.database(database))
                .where(
                    Expression.property("type").equalTo("task-list.user")
                        .and(Expression.property("taskList.id").equalTo(taskList.id)))
                .toLive()
            
            usersQuery.addChangeListener({ (change) in
                if let error = change.error {
                    NSLog("Error querying users: %@", error.localizedDescription)
                }
                self.userRows = change.rows != nil ? Array(change.rows!) : nil
                self.tableView.reloadData()
            })
        }
        
        usersQuery.run()
    }
    
    func addUser(username: String) {
        let docId = taskList.id + "." + username
        if database.contains(docId) {
            return
        }
        
        let doc = Document(docId)
        doc.set("task-list.user", forKey: "type")
        doc.set(username, forKey: "username")
        
        let taskListInfo = DictionaryObject()
        taskListInfo.set(taskList.id, forKey: "id")
        taskListInfo.set(taskList.string(forKey: "owner"), forKey: "owner")
        doc.set(taskListInfo, forKey: "taskList")
        
        do {
            try database.save(doc)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't add user", error: error)
        }
    }
    
    func deleteUser(user: Document) {
        do {
            try database.delete(user)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete user", error: error)
        }
    }
    
    func searchUser(username: String) {
        searchQuery = Query
            .select()
            .from(DataSource.database(database))
            .where(
                Expression.property("type").equalTo("task-list.user")
                    .and(Expression.property("taskList.id").equalTo(taskList.id))
                    .and(Expression.property("username").like("%" + username + "%")))
        
        do {
            let rows = try searchQuery.run()
            userRows = Array(rows)
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error search users: %@", error)
        }
    }
    
    // MARK: - UITableViewController
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userRows?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let doc = userRows![indexPath.row].document
        cell.textLabel?.text = doc.string(forKey: "username")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Delete list document:
            let doc = self.userRows![indexPath.row].document
            self.deleteUser(user: doc)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        return [delete]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        if !text.isEmpty {
            usersQuery.stop()
            self.searchUser(username: text)
        } else {
            self.reload()
        }
    }
    
    // MARK: - Action
    
    func addAction(sender: AnyObject) {
        Ui.showTextInput(on: self, title: "Add User", message: nil, textFieldConfig: { text in
            text.placeholder = "Username"
            text.autocapitalizationType = .none
        }, onOk: { username in
            self.addUser(username: username)
        })
    }
}

