//
//  ListsView.swift
//  Todo
//
//  Created by Callum Birks on 13/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI
import CouchbaseLiteSwift

struct TaskListsView: View, TodoControllerDelegate {
    @ObservedObject private var taskListsQuery: ObservableQuery
        = ObservableQuery(try! DB.shared.getTaskListsQuery())
    @State private var presentNewListAlert: Bool = false
    @State private var newListName: String = ""
    @State private var presentErrorAlert: Bool = false
    @State private var errorAlertMessage: String = ""
    @State private var errorAlertDescription: String = ""
    @State private var presentEditListAlert: Bool = false
    @State var editingTaskListID: String? = nil
    
    @State var searchText: String = ""
    private var filteredResults: [ObservableQuery.IResult] {
        if !searchText.isEmpty {
            return taskListsQuery.queryResults.filter { $0.wrappedResult.string(at: 1)!.contains(searchText) }
        } else {
            return taskListsQuery.queryResults
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredResults) { result in
                // Each row is a NavigationLink to that taskList
                NavigationLink(destination: TasksViewRoot(taskListID: result.id)) {
                    Text(result.wrappedResult.string(at: 1) ?? "Error")
                }
                .swipeActions(edge: .leading) {
                    Button("Edit") {
                        popupEditTaskList(withID: result.id)
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        TodoController.deleteTaskList(withID: result.id, delegate: self)
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationBarBackButtonHidden()
            .navigationTitle("Task Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Logout button
                    Button("Logout") {
                        AppController.logout(method: .closeDatabase)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Button to navigate to settings
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                    // Button to add task list
                    Button(action: popupAddTaskList) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .alert("New Task List", isPresented: $presentNewListAlert) {
                TextField("List name", text: $newListName)
                Button("Cancel", role: .cancel, action: {})
                Button("Create") {
                    TodoController.createTaskList(withName: newListName, delegate: self)
                }
            }
            .alert("Error", isPresented: $presentErrorAlert) {
                Button("OK", role: .cancel, action: {})
            } message: {
                Text(errorAlertMessage)
                Text(errorAlertDescription)
            }
            .alert("Edit Task List", isPresented: $presentEditListAlert) {
                TextField("List name", text: $newListName)
                Button("Cancel", role: .cancel, action: {})
                Button("Update") {
                    guard let editingTaskListID = editingTaskListID
                    else {
                        fatalError("Internal error: Editing task list without ID set")
                    }
                    TodoController.updateTaskList(withID: editingTaskListID, name: newListName, delegate: self)
                    self.editingTaskListID = nil
                }
            }
        }
    }
    
    private func popupAddTaskList() {
        newListName = ""
        presentNewListAlert = true
    }
    
    private func popupEditTaskList(withID docID: String) {
        newListName = ""
        self.editingTaskListID = docID
        presentEditListAlert = true
    }
    
// - MARK: TaskControllerDelegate
    
    public func presentError(message: String, _ error: Error?) {
        errorAlertDescription = error != nil ? error!.localizedDescription : ""
        errorAlertMessage = message
        AppController.logger.log("\(errorAlertDescription)")
        presentErrorAlert = true
    }
}
