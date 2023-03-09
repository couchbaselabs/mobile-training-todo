//
// TaskImageView.swift
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

struct TaskImageView: View, TodoControllerDelegate {
    @Environment(\.dismiss) var dismiss
    
    @State private var presentEditPhotoDialog: Bool = false
    @State private var presentPhotoLibraryPicker: Bool = false
    @State private var presentPhotoCameraPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    
    let task: Task?
    let image: Image?
    
    init(task: Task?) {
        if let task = task,
           let image = TaskImage.create(task: task) {
            self.task = task
            self.image = image
        } else {
            self.task = nil
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
                TodoController.updateTask(task!, image: nil, delegate: self)
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
                TodoController.updateTask(task!, image: image, delegate: self)
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
