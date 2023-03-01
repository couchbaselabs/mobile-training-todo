//
//  TasksView.swift
//  Todo
//
//  Created by Callum Birks on 16/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI
import CouchbaseLiteSwift

struct TasksView: View, TodoControllerDelegate {
    private let taskListID: String
    private var taskListDoc: Document? {
        guard let doc = TodoController.getTaskListDoc(fromID: self.taskListID)
        else {
            self.presentError(message: "Couldn't fetch task list doc", nil)
            return nil
        }
        return doc
    }
    @ObservedObject private var tasksQuery: ObservableQuery
    @State private var presentQEActions: Bool = false
    @State private var newTaskDeltaSync: Bool = false
    
    @State private var presentNewTaskAlert: Bool = false
    @State private var newTaskName: String = ""
    @State private var presentEditTaskAlert: Bool = false
    @State private var editingTaskID: String? = nil
    
    @State private var presentErrorAlert: Bool = false
    @State private var errorAlertMessage: String = ""
    @State private var errorAlertDescription: String = ""
    
    
    @State private var searchText: String = ""
    
    @State private var presentEditPhotoDialog: Bool = false
    @State private var presentPhotoLibraryPicker: Bool = false
    @State private var presentPhotoCameraPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    
    @State private var presentTaskImageView: Bool = false
    @State private var selectedImageTaskID: String? = nil
    
    private var filteredResults: [ObservableQuery.IResult] {
        if !searchText.isEmpty {
            return tasksQuery.queryResults.filter { $0.wrappedResult.string(forKey: "task")!.contains(searchText) }
        } else {
            return tasksQuery.queryResults
        }
    }
    
    init(taskListID: String) {
        self.taskListID = taskListID
        self._tasksQuery = ObservedObject(wrappedValue: TodoController.tasksQuery(forList: self.taskListID))
    }
    
    var body: some View {
        NavigationStack {
            // A list of tasks in the task view, displaying image, name, and a tick for completion
            // The NavigationLink covers the area of the image, and will navigate to a larger view of the image
            // Tapping the row (outside of image area) will toggle task completion
            List(filteredResults) { result in
                TaskListRow(result)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Log") {
                        try? logTask(id: result.id)
                    }
                    .tint(.gray)
                    Button("Edit") {
                        popupEditTask(taskID: result.id)
                    }
                    .tint(.blue)
                    Button("Delete", role: .destructive) {
                        TodoController.deleteTask(taskID: result.id, delegate: self)
                    }
                }
            }
            .searchable(text: $searchText)
            .onChange(of: selectedImage) { image in
                if let image = image,
                   let editingTaskID = editingTaskID {
                    TodoController.updateTask(taskID: editingTaskID, image: image, delegate: self)
                    self.editingTaskID = nil
                    selectedImage = nil
                }
            }
            .onChange(of: selectedImageTaskID) { taskID in
                if taskID != nil {
                    presentTaskImageView = true
                }
            }
            .sheet(isPresented: $presentTaskImageView) {
                NavigationStack {
                    TaskImageView(taskID: selectedImageTaskID)
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
                    TodoController.createTask(withName: newTaskName, inTaskList: self.taskListID, delegate: self)
                }
            }
            .navigationBarTitle(self.taskListDoc?.string(forKey: "name") ?? "")
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
            Button("New Task (DeltaSync)") {
                popupAddTask(withDeltaSync: true)
            }
            Button("Generate Tasks") {
                TodoController.generateTasks(taskListID: self.taskListID, withPhoto: true, delegate: self)
            }
            Button("Generate No Photo Tasks") {
                TodoController.generateTasks(taskListID: self.taskListID, withPhoto: false, delegate: self)
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
                guard let editingTaskID = editingTaskID
                else {
                    fatalError("Internal error: Editing task without ID set")
                }
                TodoController.updateTask(taskID: editingTaskID, name: newTaskName, delegate: self)
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
    
    private func TaskListRow(_ result: ObservableQuery.IResult) -> some View {
        HStack {
            if let image = TaskImage.create(taskID: result.id) {
                image.resizable()
                    .frame(width: 50, height: 50)
                    .aspectRatio(contentMode: .fill)
                    .onTapGesture {
                        presentImageView(taskID: result.id)
                    }
            } else {
                Color(.gray)
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        promptEditPhoto(taskID: result.id)
                    }
            }
            HStack {
                Text(result.wrappedResult.string(forKey: "task")!)
                Spacer()
                if result.wrappedResult.boolean(forKey: "complete") {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle()) // ensure the tappable area covers the whole row
            .onTapGesture {
                TodoController.toggleTaskComplete(taskID: result.id, delegate: self)
            }
        }
    }
    
    private func popupAddTask(withDeltaSync: Bool = false) {
        newTaskName = ""
        newTaskDeltaSync = withDeltaSync
        presentNewTaskAlert = true
    }
    
    private func presentImageView(taskID: String) {
        self.selectedImageTaskID = taskID
    }
    
    private func popupEditTask(taskID: String) {
        self.editingTaskID = taskID
        newTaskName = ""
        presentEditTaskAlert = true
    }
    
    private func promptEditPhoto(taskID: String) {
        editingTaskID = taskID
        presentEditPhotoDialog = true
    }
    
// - MARK: TaskControllerDelegate
    
    public func presentError(message: String, _ error: Error?) {
        errorAlertDescription = error != nil ? error!.localizedDescription : ""
        errorAlertMessage = message
        AppController.logger.log("\(errorAlertDescription)")
        presentErrorAlert = true
    }
}
