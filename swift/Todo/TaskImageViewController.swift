//
//  TaskImageViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/9/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLite

class TaskImageViewController: UIViewController, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    var database: CBLDatabase!
    var task: CBLDocument!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get database:
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database
        
        reload()
    }

    // MARK: - Action
    
    @IBAction func editAction(_ sender: AnyObject) {
        Ui.showImageActionSheet(
            onController: self,
            withImagePickerDelegate: self,
            onDelete: {
                self.deleteImage()
            }
        )
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
        if let blob = task["image"] as? CBLBlob, let content = blob.content {
            imageView.image = UIImage(data: content)
        } else {
            imageView.image = nil
        }
    }
    
    func updateImage(image: UIImage) {
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                                 withMessage: "Invalid image format")
            return
        }
        
        do {
            task["image"] = try! CBLBlob.init(contentType: "image/jpg", data: imageData)
            try task.save()
            reload()
        } catch let error as NSError {
            Ui.showErrorDialog(onController: self, withMessage: "Couldn't update image", withError: error)
        }
    }
    
    func deleteImage() {
        do {
            task["image"] = nil
            try task.save()
        } catch let error as NSError {
            Ui.showErrorDialog(onController: self, withMessage: "Couldn't delete image", withError: error)
        }
    }
}
