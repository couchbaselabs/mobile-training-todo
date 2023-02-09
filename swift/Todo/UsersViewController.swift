//
// UsersViewController.swift
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

class UsersViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    var searchController: UISearchController!
    
    var username: String!
    var taskList: Document?
    
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
        
        // Get current username
        username = Session.username
        
        // Load data:
        reload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let taskList = self.taskList else { return }
        
        self.tabBarController?.title = taskList.string(forKey: "name")
        self.tabBarController?.navigationItem.rightBarButtonItem =
        UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAction(sender:)))
    }
    
    // MARK: - Database
    
    func reload() {
        guard let taskList = self.taskList else { return }
        
        if usersQuery == nil {
            usersQuery = try! DB.shared.getSharedUsersQuery(taskList: taskList)
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
        do {
            try DB.shared.addSharedUser(taskList: taskList!, username: username)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't add user", error: error)
        }
    }
    
    func deleteUser(userID: String) {
        do {
            try DB.shared.deleteSharedUser(userID: userID)
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete user", error: error)
        }
    }
    
    func searchUser(username: String) {
        do {
            let rs = try DB.shared.getSharedUsersByUsername(taskList: taskList!, username: username)
            searchRows = Array(rs)
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
        let id = row.string(at: 0)!
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action, indexPath) -> Void in
            // Dismiss row actions:
            tableView.setEditing(false, animated: true)
            // Delete list document:
            self.deleteUser(userID: id)
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

