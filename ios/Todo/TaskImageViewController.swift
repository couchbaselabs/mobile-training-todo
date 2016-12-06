//
//  TaskImageViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/9/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit

class TaskImageViewController: UIViewController, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    var task: CBLDocument!
    var database: CBLDatabase!

    var currentImage: CBLAttachment?
    var docChangeObserver: AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get database:
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database

        if docChangeObserver == nil {
            docChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.cblDocumentChange, object: task, queue: nil) { note in
                if let change = note.userInfo?["change"] as? CBLDatabaseChange {
                    if change.source == nil || !change.isCurrentRevision {
                        return
                    }
                    
                    if let rev = self.task.currentRevision {
                        let digest = rev.attachmentNamed("image")?.metadata["digest"] as? String
                        let currentDigest = self.currentImage?.metadata["digest"] as? String
                        if digest != currentDigest {
                            self.reloadImage()
                        }
                    }
                }
            }
        }
        
        reloadImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        if docChangeObserver != nil {
            NotificationCenter.default.removeObserver(docChangeObserver!)
        }
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
    
    func reloadImage() {
        currentImage = task.currentRevision?.attachmentNamed("image")
        if let data = currentImage?.content {
            imageView.image = UIImage(data: data)
        } else {
            imageView.image = nil
        }
    }
    
    func updateImage(image: UIImage) {
        let newRev = task.newRevision()
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Invalid image format")
            return
        }
        newRev.setAttachmentNamed("image", withContentType: "image/jpg", content: imageData)
        do {
            try newRev.save()
            reloadImage()
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't add image", withError: error)
        }
    }
    
    func deleteImage() {
        let newRev = task.newRevision()
        newRev.removeAttachmentNamed("image")
        do {
            try newRev.save()
            dismiss(animated: true, completion: nil)
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't delete image", withError: error)
        }
    }
}
