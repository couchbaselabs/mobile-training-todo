//
// ImagePicker.swift
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

import PhotosUI
import SwiftUI

// We have two separate classes, one for getting images from photo library, and one for taking photos with camera
// This is because the newer PHPicker only supports the photo library, and the photo library mode of UIImagePicker
// will soon be deprecated (so we only use UIImagePicker for the camera source)

// These classes are a way of integrating the UIKit elements into SwiftUI. That is necessary because currently, there
// is only a very basic photo library picker built-in to SwiftUI, and none for the camera

struct ImagePicker {
    struct Library: UIViewControllerRepresentable {
        @Binding var image: UIImage?
    
        func makeUIViewController(context: Context) -> PHPickerViewController {
            var config = PHPickerConfiguration()
            config.selectionLimit = 1
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
            
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, PHPickerViewControllerDelegate {
            let parent: ImagePicker.Library
            
            init(_ parent: ImagePicker.Library) {
                self.parent = parent
            }
            
            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true)
                guard let provider = results.first?.itemProvider
                else { return }
                
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
    
    struct Camera: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            var controller = UIImagePickerController()
            controller.allowsEditing = false
            controller.sourceType = .camera
            controller.delegate = context.coordinator
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
            
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePicker.Camera
            
            init(_ parent: ImagePicker.Camera) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
                picker.dismiss(animated: true)
                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    parent.image = image
                }
            }
        }
    }
}
