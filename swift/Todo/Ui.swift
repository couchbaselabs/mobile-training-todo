//
//  Ui.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit

class Ui {
    class func showTextInput(on controller: UIViewController,
                             title: String?,
                             message: String?,
                             textFieldConfig: ((UITextField) -> Void)?,
                             onOk: ((String) -> Void)?)
    {
        let dialog = TextDialog()
        dialog.title = title
        dialog.message = message
        dialog.textFieldConfig = textFieldConfig
        dialog.onOkAction = onOk
        dialog.show(controller: controller)
    }
    
    class func showMessage(on controller: UIViewController,
                           title: String?,
                           message: String?,
                           error: NSError? = nil,
                           onClose: (() -> Void)? = nil)
    {
        var mesg: String?
        if let err = error {
            mesg = "\(message ?? "")\n\n\(err.localizedDescription)"
            NSLog("Error: %@ (error=%@)", message!, (error ?? ""))
        } else {
            mesg = message
        }
        
        let alert = UIAlertController(title: title, message: mesg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (_) in
            if let action = onClose {
                action()
            }
        })
        controller.present(alert, animated: true, completion: nil)
    }
    
    class func showError(on controller: UIViewController, message: String?, error: NSError? = nil) {
        showMessage(on: controller, title: "Error", message: message, error: error, onClose: nil)
    }
    
    class func showImageActionSheet(on controller: UIViewController,
                                    imagePickerDelegate delegate:
                                    UIImagePickerControllerDelegate & UINavigationControllerDelegate,
                                    onDelete: (() -> Void)? = nil)
    {
        let alert = UIAlertController(title: nil, message: nil,
                                      preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                showImagePicker(on: controller, sourceType: .camera, delegate: delegate)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Choose Existing", style: .default) { _ in
            showImagePicker(on: controller, sourceType: .photoLibrary, delegate: delegate)
        })
        
        if let action = onDelete {
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                action()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        
        controller.present(alert, animated: true, completion: nil)
    }
    
    class func showImagePicker(on controller: UIViewController,
                               sourceType: UIImagePickerControllerSourceType!,
                               delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = delegate
        controller.present(imagePicker, animated: true, completion: nil)
    }
    
    class func displayOrHideTabbar(on controller: UIViewController, display: Bool) {
        guard let tabBar = controller.tabBarController?.tabBar else {
            return
        }
        
        if display == tabBar.isHidden {
            tabBar.isHidden = !display
            if tabBar.isHidden {
                controller.tabBarController!.selectedIndex = 0
            }
            
            // Workaround for resizing table view:
            if let tableViewController = controller as? UITableViewController {
                let tableView = tableViewController.tableView!
                if display {
                    tableView.frame = CGRect(
                        x: tableView.frame.origin.x,
                        y: tableView.frame.origin.y,
                        width: tableView.frame.size.width,
                        height: tableView.frame.size.height - tabBar.frame.size.height)
                } else {
                    tableView.frame = CGRect(
                        x: tableView.frame.origin.x,
                        y: tableView.frame.origin.y,
                        width: tableView.frame.size.width,
                        height: tableView.frame.size.height + tabBar.frame.size.height)
                }
            }
        }
    }
}
