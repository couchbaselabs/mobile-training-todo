//
//  UsersView.swift
//  Todo
//
//  Created by Callum Birks on 20/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI

struct UsersView: View, TodoControllerDelegate {
    private let taskListID: String
    @ObservedObject private var usersQuery: ObservableQuery
    @State private var searchText: String = ""
    
    @State private var presentAddUserAlert: Bool = false
    @State private var newUsername: String = ""
    
    @State private var presentErrorAlert: Bool = false
    @State private var errorAlertMessage: String = ""
    @State private var errorAlertDescription: String = ""
    
    private var filteredResults: [ObservableQuery.IResult] {
        if !searchText.isEmpty {
            return usersQuery.queryResults.filter { $0.wrappedResult.string(at: 1)!.contains(searchText) }
        } else {
            return usersQuery.queryResults
        }
    }
    
    init(taskListID: String) {
        self.taskListID = taskListID
        self._usersQuery = ObservedObject(wrappedValue: TodoController.usersQuery(forList: self.taskListID))
    }
    
    var body: some View {
        NavigationStack {
            List(filteredResults) { result in
                Text(result.wrappedResult.string(at: 1)!)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            TodoController.deleteSharedUser(userID: result.id, delegate: self)
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
            TextField("Username", text: $newUsername)
            Button("Cancel", role: .cancel, action: {})
            Button("Add") {
                if !newUsername.isEmpty {
                    TodoController.addUser(toTaskList: self.taskListID, username: newUsername, delegate: self)
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
        AppController.logger.log("\(errorAlertDescription)")
        presentErrorAlert = true
    }
}
