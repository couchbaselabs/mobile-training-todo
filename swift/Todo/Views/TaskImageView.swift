//
//  TaskImageView.swift
//  Todo
//
//  Created by Callum Birks on 16/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI

struct TaskImageView: View, TodoControllerDelegate {
    @Environment(\.dismiss) var dismiss
    let taskID: String
    let image: Image?
    @State private var presentEditPhotoDialog: Bool = false
    @State private var presentPhotoLibraryPicker: Bool = false
    @State private var presentPhotoCameraPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    
    init(taskID: String?) {
        if let taskID = taskID,
           let image = TaskImage.create(taskID: taskID) {
            self.taskID = taskID
            self.image = image
        } else {
            self.taskID = ""
            self.image = nil
            self.presentError(message: "Couldn't load image for task", nil)
        }
    }
    
    var body: some View {
        VStack {
            if let image = self.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("Couldn't load image - task ID was null")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close", role: .cancel) {
                    self.dismiss()
                }
            }
            if self.image != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        presentEditPhotoDialog = true
                    }
                }
            }
        }
        .confirmationDialog("Edit Photo", isPresented: $presentEditPhotoDialog, titleVisibility: .hidden) {
            Button("Take Photo") {
                presentPhotoCameraPicker = true
            }
            Button("Choose Existing") {
                presentPhotoLibraryPicker = true
            }
            Button("Delete Photo", role: .destructive) {
                guard TodoController.deleteImage(taskID: self.taskID)
                else {
                    self.presentError(message: "Error deleting image", nil)
                    return
                }
                self.dismiss()
            }
        }
        .sheet(isPresented: $presentPhotoLibraryPicker) {
            ImagePicker.Library(image: $selectedImage)
        }
        .sheet(isPresented: $presentPhotoCameraPicker) {
            ImagePicker.Camera(image: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                TodoController.updateTask(taskID: self.taskID, image: image, delegate: self)
                selectedImage = nil
            }
        }
    }
    
    public func presentError(message: String, _ error: Error?) {
        let errDesc = error != nil ? error!.localizedDescription : ""
        AppController.logger.log("\(message), \(errDesc)")
        self.dismiss()
    }
}
