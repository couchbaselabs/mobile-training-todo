//
// TaskImageViewController.swift
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

class TaskImageViewController: UIViewController, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    var taskID: String!
    var imageBlob: Blob?
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
    }

    // MARK: - Action
    
    @IBAction func editAction(_ sender: AnyObject) {
        Ui.showImageActionSheet(on: self, imagePickerDelegate: self, onDelete: {
            self.deleteImage()
        })
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        dismissController()
    }
    
    func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        updateImage(image: info["UIImagePickerControllerOriginalImage"] as! UIImage)
        picker.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Database
    
    func reload() {
        if let image = self.image {
            imageView.image = image
        } else if let data = imageBlob?.content {
            imageView.image = UIImage(data: data)
        } else {
            imageView.image = nil
        }
    }
    
    func updateImage(image: UIImage) {
        do {
            try DB.shared.updateTask(taskID: taskID, image: image)
            self.image = image
            self.imageBlob = nil
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't update image", error: error)
        }
    }
    
    func deleteImage() {
        do {
            try DB.shared.updateTask(taskID: taskID, image: nil)
            self.image = nil
            self.imageBlob = nil
            reload()
        } catch let error as NSError {
            Ui.showError(on: self, message: "Couldn't delete image", error: error)
        }
    }
}
