//
// ListsView.swift
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

struct TaskListsView: View, TodoControllerDelegate {
    @ObservedObject private var taskListsQuery = TodoController.taskListsQuery()
        
    @State private var presentNewListAlert: Bool = false
    @State private var newListName: String = ""
    @State private var presentErrorAlert: Bool = false
    @State private var errorAlertMessage: String = ""
    @State private var errorAlertDescription: String = ""
    @State private var presentEditListAlert: Bool = false
    @State var editingTaskList: TaskList? = nil
    
    private var filteredResults: [any QueryResultProtocol] {
            return taskListsQuery.change.results
    }
    
    var body: some View {
        NavigationStack {
            List(filteredResults, id: \.id) { result in
                let taskList = TaskList.init(result: result)
                // Each row is a NavigationLink to that taskList
                NavigationLink(destination: TasksViewRoot(taskList: taskList)) {
                    Text(taskList.name)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Log") {
                                TodoController.logTaskList(taskList)
                            }
                            .tint(.gray)
                            Button("Edit") {
                                popupEditTaskList(taskList)
                            }
                            .tint(.blue)
                            Button("Delete", role: .destructive) {
                                TodoController.deleteTaskList(taskList, delegate: self)
                            }
                        }
                }
            }
            .onAppear {
                print("")
            }
            .onDisappear {
                print("")
            }
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
                    SwiftUI.Task {
                        await TodoController.createTaskList(name: newListName, delegate: self)
                    }
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
                    guard var editingTaskList = editingTaskList else {
                        fatalError("Internal error: Editing task list without selecting a task list")
                    }
                    editingTaskList.name = newListName
                    TodoController.updateTaskList(editingTaskList, delegate: self)
                    self.editingTaskList = nil
                }
            }
        }
    }
    
    private func popupAddTaskList() {
        newListName = ""
        presentNewListAlert = true
    }
    
    private func popupEditTaskList(_ taskList: TaskList) {
        newListName = ""
        self.editingTaskList = taskList
        presentEditListAlert = true
    }
    
    // - MARK: TaskControllerDelegate
    
    public func presentError(message: String, _ error: Error?) {
        errorAlertDescription = error != nil ? error!.localizedDescription : ""
        errorAlertMessage = message
        AppController.logger.log("[Todo] Lists Error: \(errorAlertDescription)")
        presentErrorAlert = true
    }
    
}
