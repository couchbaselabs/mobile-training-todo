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
            dialog.show(controller: controller)
    }

    class func showEncryptionErrorDialog(
        onController controller: UIViewController,
        onMigrateAction migrateAction: @escaping ((String) -> Void),
        onDeleteAction deleteAction: @escaping (() -> Void)) {
            let dialog = TextDialog()
            dialog.title = "Password Changed"
            dialog.message = "Please enter your old password to migrate your database."
            dialog.textFieldConfig = { textField in
                textField.placeholder = "old password"
                textField.isSecureTextEntry = true
                textField.autocapitalizationType = .none
            }
            dialog.okButtonTitle = "Migrate"
            dialog.cancelButtonTitle = "Delete"
            dialog.cancelButtonStyle = UIAlertActionStyle.destructive
            dialog.onOkAction = migrateAction
            dialog.onCancelAction = deleteAction
            dialog.show(controller: controller)
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

            let alert = UIAlertController(title: title, message: mesg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (_) in
                if let action = closeAction {
                    action()
                }
            })
            controller.present(alert, animated: true, completion: nil)
    }
    
    class func showImageActionSheet(
        onController controller: UIViewController,
        withImagePickerDelegate delegate:
        UIImagePickerControllerDelegate & UINavigationControllerDelegate,
        onDelete deleteAction: (() -> Void)? = nil) {
            let alert = UIAlertController(title: nil, message: nil,
                preferredStyle: .actionSheet)
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                    showImagePicker(onController: controller, withImageSourceType: .camera,
                        withImagePickerDelegate: delegate)
                })
            }
            
            alert.addAction(UIAlertAction(title: "Choose Existing", style: .default) { _ in
                showImagePicker(onController: controller, withImageSourceType: .photoLibrary,
                    withImagePickerDelegate: delegate)
            })
            
            if let action = deleteAction {
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    action()
                })
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
            
            controller.present(alert, animated: true, completion: nil)
    }
    
    class func showImagePicker(
        onController controller: UIViewController,
        withImageSourceType sourceType: UIImagePickerControllerSourceType!,
        withImagePickerDelegate delegate:
        UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = sourceType
            imagePicker.delegate = delegate
            controller.present(imagePicker, animated: true, completion: nil)
    }
    
    class func displayOrHideTabbar(
        onController controller: UIViewController,
        withDisplay display: Bool) {
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
