//
// UsersView.swift
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

import SwiftUI

struct UsersView: View, TodoControllerDelegate {
    @ObservedObject private var usersQuery: LiveQueryObject
    
    @State private var searchText: String = ""
    
    @State private var presentAddUserAlert: Bool = false
    @State private var newUsername: String = ""
    
    @State private var presentErrorAlert: Bool = false
    @State private var errorAlertMessage: String = ""
    @State private var errorAlertDescription: String = ""
    
    private let taskList: TaskList
    
    private var filteredResults: [any QueryResultProtocol] {
        if !searchText.isEmpty {
            return usersQuery.change.results.filter { $0.string(forKey: "username")!.contains(searchText) }
        } else {
            return usersQuery.change.results
        }
    }
    
    init(taskList: TaskList) {
        self.taskList = taskList
        self.usersQuery = TodoController.usersQuery(for: taskList)
    }
    
    var body: some View {
        NavigationStack {
            List(filteredResults, id: \.id) { result in
                let user = User.init(result: result)
                Text(user.username)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            TodoController.deleteUser(user, delegate: self)
                        }
                    }
            }
            .searchable(text: $searchText)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    popupAddUser()
                } label: {
                    Label("Add User", systemImage: "plus")
                }
            }
        }
        .alert("Add User", isPresented: $presentAddUserAlert) {
            TextField("Username", text: $newUsername).textInputAutocapitalization(.never)
            Button("Cancel", role: .cancel, action: {})
            Button("Add") {
                if !newUsername.isEmpty {
                    TodoController.addUser(newUsername, for: taskList, delegate: self)
                }
            }
        }
        // Error alert
        .alert("Error", isPresented: $presentErrorAlert) {
            Button("OK", role: .cancel, action: {})
        } message: {
            Text(errorAlertMessage)
            Text(errorAlertDescription)
        }
    }
    
    public func popupAddUser() {
        newUsername = ""
        presentAddUserAlert = true
    }
    
    // - MARK: TaskControllerDelegate
    
    public func presentError(message: String, _ err: Error?) {
        errorAlertDescription = err != nil ? err!.localizedDescription : ""
        errorAlertMessage = message
        AppController.logger.log("[Todo] Users Error: \(errorAlertDescription)")
        presentErrorAlert = true
    }
}
