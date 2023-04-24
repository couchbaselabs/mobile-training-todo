//
// TasksView.swift
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

struct TasksView: View, TodoControllerDelegate {
    @ObservedObject private var tasksQuery: LiveQueryObject
    
    @State private var presentQEActions: Bool = false
    
    @State private var presentNewTaskAlert: Bool = false
    @State private var newTaskName: String = ""
    @State private var presentEditTaskAlert: Bool = false
    @State private var editingTask: Task? = nil
    
    @State private var presentErrorAlert: Bool = false
    @State private var errorAlertMessage: String = ""
    @State private var errorAlertDescription: String = ""
    
    @State private var presentEditPhotoDialog: Bool = false
    @State private var presentPhotoLibraryPicker: Bool = false
    @State private var presentPhotoCameraPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    
    @State private var presentTaskImageView: Bool = false
    @State private var selectedImageTask: Task? = nil
    
    private let taskList: TaskList
    
    private var filteredResults: [any QueryResultProtocol] {
            return tasksQuery.change.results
    }
    
    init(taskList: TaskList) {
        self.taskList = taskList
        self.tasksQuery = TodoController.tasksQuery(for: taskList)
    }
    
    var body: some View {
        NavigationStack {
            // A list of tasks in the task view, displaying image, name, and a tick for completion
            // The NavigationLink covers the area of the image, and will navigate to a larger view of the image
            // Tapping the row (outside of image area) will toggle task completion
            List(filteredResults, id: \.id) { result in
                let task = Task.init(result: result)
                TaskRow(task)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Log") {
                        TodoController.logTask(task)
                    }
                    .tint(.gray)
                    Button("Edit") {
                        popupEditTask(task)
                    }
                    .tint(.blue)
                    Button("Delete", role: .destructive) {
                        TodoController.deleteTask(task, delegate: self)
                    }
                }
            }
            .onChange(of: selectedImage) { image in
                if let image = image, let editingTask = editingTask {
                    TodoController.updateTask(editingTask, image: image, delegate: self)
                    self.editingTask = nil
                    selectedImage = nil
                }
            }
            .onChange(of: selectedImageTask) { task in
                if task != nil {
                    presentTaskImageView = true
                }
            }
            .sheet(isPresented: $presentTaskImageView) {
                NavigationStack {
                    TaskImageView(task: selectedImageTask)
                }
            }
            .sheet(isPresented: $presentPhotoLibraryPicker) {
                ImagePicker.Library(image: $selectedImage)
            }
            .sheet(isPresented: $presentPhotoCameraPicker) {
                ImagePicker.Camera(image: $selectedImage)
            }
            // New Task creation alert
            .alert("New Task", isPresented: $presentNewTaskAlert) {
                TextField("Task name", text: $newTaskName)
                Button("Cancel", role: .cancel, action: {})
                Button("Create") {
                    TodoController.createTask(name: newTaskName, for: taskList, delegate: self)
                }
            }
            .navigationBarTitle(taskList.name)
        }
        .toolbar {
            // Add button which presents QE Actions dialog
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { presentQEActions = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        // QE Actions confirmation dialog
        .confirmationDialog("QE Actions", isPresented: $presentQEActions, titleVisibility: .hidden) {
            Button("New Task") {
                popupAddTask()
            }
            Button("Generate Tasks") {
                TodoController.generateTasks(for: taskList, withPhoto: true, numbers: 50, delegate: self)
            }
            Button("Generate No Photo Tasks") {
                TodoController.generateTasks(for: taskList, withPhoto: false, numbers: 50, delegate: self)
            }
            Button("Cancel", role: .cancel, action: {})
        }
        .confirmationDialog("Edit Photo", isPresented: $presentEditPhotoDialog, titleVisibility: .hidden) {
            Button("Take Photo") {
                presentPhotoCameraPicker = true
            }
            Button("Choose Existing") {
                presentPhotoLibraryPicker = true
            }
        }
        // Edit Task alert
        .alert("Edit Task", isPresented: $presentEditTaskAlert) {
            TextField("Task name", text: $newTaskName)
            Button("Cancel", role: .cancel, action: {})
            Button("Update") {
                guard var editingTask = editingTask else {
                    fatalError("Internal error: Editing task without selecting task")
                }
                editingTask.task = newTaskName
                TodoController.updateTask(editingTask, delegate: self)
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
    
    private func TaskRow(_ task: Task) -> some View {
        HStack {
            if let image = TaskImage.create(task: task) {
                image.resizable()
                    .frame(width: 50, height: 50)
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        presentImageView(task: task)
                    }
            } else {
                Color(.gray)
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        promptEditPhoto(task: task)
                    }
            }
            HStack {
                Text(task.task)
                Spacer()
                if task.complete {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle()) // ensure the tappable area covers the whole row
            .onTapGesture {
                var updated = task
                updated.complete = !task.complete
                TodoController.updateTask(updated, delegate: self)
            }
        }
    }
    
    private func popupAddTask() {
        newTaskName = ""
        presentNewTaskAlert = true
    }
    
    private func presentImageView(task: Task) {
        self.selectedImageTask = task
    }
    
    private func popupEditTask(_ task: Task) {
        self.editingTask = task
        newTaskName = ""
        presentEditTaskAlert = true
    }
    
    private func promptEditPhoto(task: Task) {
        editingTask = task
        presentEditPhotoDialog = true
    }
    
    // - MARK: TaskControllerDelegate
    
    public func presentError(message: String, _ error: Error?) {
        errorAlertDescription = error != nil ? error!.localizedDescription : ""
        errorAlertMessage = message
        AppController.logger.log("[Todo] Tasks Error: \(errorAlertDescription)")
        presentErrorAlert = true
    }
}
