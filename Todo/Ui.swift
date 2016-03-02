//
//  Ui.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import Foundation

class Ui {
    class func showTextInputDialog(
        onController controller: UIViewController,
        withTitle title: String?,
        withMessage message: String?,
        withTextFieldConfig textFieldConfig: ((UITextField) -> Void)?,
        onOk onOkAction: ((String) -> Void)?) {
            let dialog = TextDialog()
            dialog.title = title
            dialog.message = message
            dialog.textFieldConfig = textFieldConfig
            dialog.onOkAction = onOkAction
            dialog.show(controller)
    }

    class func showEncryptionErrorDialog(
        onController controller: UIViewController,
        onMigrateAction migrateAction: ((String) -> Void),
        onDeleteAction deleteAction: (() -> Void)) {
            let dialog = TextDialog()
            dialog.title = "Password Changed"
            dialog.message = "Please enter your old password to migrate your database."
            dialog.textFieldConfig = { textField in
                textField.placeholder = "old password"
                textField.secureTextEntry = true
                textField.autocapitalizationType = .None
            }
            dialog.okButtonTitle = "Migrate"
            dialog.cancelButtonTitle = "Delete"
            dialog.cancelButtonStyle = UIAlertActionStyle.Destructive
            dialog.onOkAction = migrateAction
            dialog.onCancelAction = deleteAction
            dialog.show(controller)
    }
    
    class func showMessageDialog(
        onController controller: UIViewController,
        withTitle title: String?,
        withMessage message: String?,
        withError error: NSError? = nil,
        onClose closeAction: (() -> Void)? = nil) {
            var mesg: String?
            if let err = error {
                mesg = "\(message)\n\n\(err.localizedDescription)"
                NSLog("Error: %@ (error=%@)", message!, (error ?? ""))
            } else {
                mesg = message
            }

            let alert = UIAlertController(title: title, message: mesg, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel) { (_) in
                if let action = closeAction {
                    action()
                }
            })
            controller.presentViewController(alert, animated: true, completion: nil)
    }
    
    class func showImageActionSheet(
        onController controller: UIViewController,
        withImagePickerDelegate delegate:
        protocol<UIImagePickerControllerDelegate, UINavigationControllerDelegate>?,
        onDelete deleteAction: (() -> Void)? = nil) {
            let alert = UIAlertController(title: nil, message: nil,
                preferredStyle: .ActionSheet)
            
            if UIImagePickerController.isSourceTypeAvailable(.Camera) {
                alert.addAction(UIAlertAction(title: "Take Photo", style: .Default) { _ in
                    showImagePicker(onController: controller, withImageSourceType: .Camera,
                        withImagePickerDelegate: delegate)
                })
            }
            
            alert.addAction(UIAlertAction(title: "Choose Existing", style: .Default) { _ in
                showImagePicker(onController: controller, withImageSourceType: .PhotoLibrary,
                    withImagePickerDelegate: delegate)
            })
            
            if let action = deleteAction {
                alert.addAction(UIAlertAction(title: "Delete", style: .Destructive) { _ in
                    action()
                })
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { _ in })
            
            controller.presentViewController(alert, animated: true, completion: nil)
    }
    
    class func showImagePicker(
        onController controller: UIViewController,
        withImageSourceType sourceType: UIImagePickerControllerSourceType!,
        withImagePickerDelegate delegate:
        protocol<UIImagePickerControllerDelegate, UINavigationControllerDelegate>?) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = sourceType
            imagePicker.delegate = delegate
            controller.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    class func displayOrHideTabbar(
        onController controller: UIViewController,
        withDisplay display: Bool) {
            guard let tabBar = controller.tabBarController?.tabBar else {
                return
            }
            
            if display == tabBar.hidden {
                tabBar.hidden = !display
                if tabBar.hidden {
                    controller.tabBarController!.selectedIndex = 0
                }
                
                // Workaround for resizing table view:
                if let tableViewController = controller as? UITableViewController {
                    let tableView = tableViewController.tableView
                    if display {
                        tableView.frame = CGRectMake(
                            tableView.frame.origin.x,
                            tableView.frame.origin.y,
                            tableView.frame.size.width,
                            tableView.frame.size.height - tabBar.frame.size.height)
                    } else {
                        tableView.frame = CGRectMake(
                            tableView.frame.origin.x,
                            tableView.frame.origin.y,
                            tableView.frame.size.width,
                            tableView.frame.size.height + tabBar.frame.size.height)
                    }
                }
            }
    }
}