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
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        database = app.database

        if docChangeObserver == nil {
            docChangeObserver = NSNotificationCenter.defaultCenter().addObserverForName(
                kCBLDocumentChangeNotification, object: task, queue: nil) { (note) -> Void in
                    if let change = note.userInfo!["change"] as? CBLDatabaseChange {
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    deinit {
        if docChangeObserver != nil {
            NSNotificationCenter.defaultCenter().removeObserver(docChangeObserver!)
        }
    }

    // MARK: - Action
    
    @IBAction func editAction(sender: AnyObject) {
        Ui.showImageActionSheet(onController: self, withImagePickerDelegate: self,
            onDelete: { () -> Void in
                self.deleteImage()
            }
        )
    }
    
    @IBAction func closeAction(sender: AnyObject) {
        dismissController()
    }

    func dismissController() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
            updateImage(image)
            picker.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
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
            dismissViewControllerAnimated(true, completion: nil)
        } catch let error as NSError {
            Ui.showMessageDialog(onController: self, withTitle: "Error",
                withMessage: "Couldn't delete image", withError: error)
        }
    }
}
