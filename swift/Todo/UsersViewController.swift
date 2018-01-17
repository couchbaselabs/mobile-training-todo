//
//  UsersViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 6/16/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class UsersViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    var searchController: UISearchController!
    
    var username: String!
    var database: Database!
    var taskList: Document!
    
    var usersQuery: Query!
    var userRows : [Result]?
    
    var searchQuery: Query!
    var inSearch = false;
    var searchRows : [Result]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
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
                .select(S_ID, S_USERNAME)
                .from(DataSource.database(database))
                .where(TYPE.equalTo(Expression.string("task-list.user")).and(TASK_LIST_ID.equalTo(Expression.string(taskList.id))))
            
            usersQuery.addChangeListener({ (change) in
                if let error = change.error {
                    NSLog("Error querying users: %@", error.localizedDescription)
                }
                self.userRows = change.results != nil ? Array(change.results!) : nil
                self.tableView.reloadData()
            })
        }
    }
    
    func addUser(username: String) {
        let docId = taskList.id + "." + username
        if database.document(withID: docId) != nil {
            return
        }
        
        let doc = MutableDocument(withID: docId)
        doc.setValue("task-list.user", forKey: "type")
        doc.setValue(username, forKey: "username")
        
        let taskListInfo = MutableDictionaryObject()
        taskListInfo.setValue(taskList.id, forKey: "id")
        taskListInfo.setValue(taskList.string(forKey: "owner"), forKey: "owner")
        doc.setValue(taskListInfo, forKey: "taskList")
        
        do {
            try database.saveDocument(doc)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't add user", error: error)
        }
    }
    
    func deleteUser(user: Document) {
        do {
            try database.deleteDocument(user)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete user", error: error)
        }
    }
    
    func searchUser(username: String) {
        searchQuery = Query
            .select(S_ID, S_USERNAME)
            .from(DataSource.database(database))
            .where(TYPE.equalTo(Expression.string("task-list.user"))
                .and(TASK_LIST_ID.equalTo(Expression.string(taskList.id)))
                .and(USERNAME.like(Expression.string("%" + username + "%"))))
        
        do {
            let rows = try searchQuery.execute()
            searchRows = Array(rows)
            tableView.reloadData()
        } catch let error as NSError {
            NSLog("Error search users: %@", error)
        }
    }
    
    // MARK: - UITableViewController
    
    var data: [Result]? {
        return inSearch ? searchRows : userRows
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let row = self.data![indexPath.row]
        cell.textLabel?.text = row.string(at: 1)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let row = self.data![indexPath.row]
        let docID = row.string(at: 0)!
        let doc = database.document(withID: docID)!
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Delete list document:
            self.deleteUser(user: doc)
        }
        delete.backgroundColor = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        return [delete]
    }
    
    // MARK: - UISearchController
    
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        if !text.isEmpty {
            inSearch = true
            self.searchUser(username: text)
        } else {
            searchBarCancelButtonClicked(searchController.searchBar)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        inSearch = false
        searchRows = nil
        self.tableView.reloadData()
    }
    
    // MARK: - Action
    
    @objc func addAction(sender: AnyObject) {
        Ui.showTextInput(on: self, title: "Add User", message: nil, textFieldConfig: { text in
            text.placeholder = "Username"
            text.autocapitalizationType = .none
        }, onOk: { username in
            self.addUser(username: username)
        })
    }
}

