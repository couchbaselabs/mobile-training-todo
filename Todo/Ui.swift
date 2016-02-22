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
        onController controller: UIViewController!,
        withTitle title: String?,
        withMessage message: String?,
        withTextFieldConfig textFieldConfig: ((UITextField) -> Void)?,
        onOk onOkAction: ((String) -> Void)?) {
            showTextInputDialog(
                onController: controller,
                withTitle: title,
                withMessage: message,
                withTextFieldConfig: textFieldConfig,
                withOkConfig: nil,
                withCancelConfig: nil,
                onOk: onOkAction,
                onCancel: nil)
    }

    class func showTextInputDialog(
        onController controller: UIViewController!,
        withTitle title: String?,
        withMessage message: String?,
        withTextFieldConfig textFieldConfig: ((UITextField) -> Void)?,
        withOkConfig okConflig: (() -> (title: String, style: UIAlertActionStyle))?,
        withCancelConfig cancelConflig: (() -> (title: String, style: UIAlertActionStyle))?,
        onOk onOkAction: ((String) -> Void)?,
        onCancel onCancelAction: (() -> Void)?) {
            var observer: NSObjectProtocol?
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

            // OK:
            var ok = (title: "OK", style: UIAlertActionStyle.Default)
            if let okConfigHandler = okConflig {
                ok = okConfigHandler()
            }
            let okAction = UIAlertAction(title: ok.title, style: ok.style) { (_) in
                let textField = alert.textFields![0] as UITextField
                if let curObserver = observer {
                    NSNotificationCenter.defaultCenter().removeObserver(curObserver)
                }
                if let action = onOkAction, text = textField.text {
                    action(text)
                }
            }
            okAction.enabled = false
            alert.addAction(okAction)

            // Cancel:
            var cancel = (title: "Cancel", style: UIAlertActionStyle.Cancel)
            if let cancelConfligHandler = cancelConflig {
                cancel = cancelConfligHandler()
            }
            let cancelAction = UIAlertAction(title: cancel.title, style: cancel.style) { (_) in
                if let curObserver = observer {
                    NSNotificationCenter.defaultCenter().removeObserver(curObserver)
                }
            }
            alert.addAction(cancelAction)

            // TextField:
            alert.addTextFieldWithConfigurationHandler { (textField) in
                if let textFieldConfigHandler = textFieldConfig {
                    textFieldConfigHandler(textField)
                }
                observer =  NSNotificationCenter.defaultCenter().addObserverForName(
                    UITextFieldTextDidChangeNotification,
                    object: textField,
                    queue: NSOperationQueue.mainQueue()) { (notification) in
                        okAction.enabled = textField.text != ""
                }
            }

            // Workaround for UICollectionViewFlowLayout is not defined warning:
            alert.view.setNeedsLayout()
            controller.presentViewController(alert, animated: true, completion: nil)
    }

    class func showMessageDialog(
        onController controller: UIViewController!,
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
        onController controller: UIViewController!,
        withImagePickerDelegate delegate:
        protocol<UIImagePickerControllerDelegate, UINavigationControllerDelegate>?,
        onDelete deleteAction: (() -> Void)? = nil) {
            let alert = UIAlertController(title: nil, message: nil,
                preferredStyle: .ActionSheet)
            
            if UIImagePickerController.isSourceTypeAvailable(.Camera) {
                alert.addAction(UIAlertAction(title: "Take Photo", style: .Default) { (_) in
                    showImagePicker(onController: controller, withImageSourceType: .Camera,
                        withImagePickerDelegate: delegate)
                })
            }
            
            alert.addAction(UIAlertAction(title: "Choose Existing", style: .Default) { (_) in
                showImagePicker(onController: controller, withImageSourceType: .PhotoLibrary,
                    withImagePickerDelegate: delegate)
            })
            
            if let action = deleteAction {
                alert.addAction(UIAlertAction(title: "Delete", style: .Destructive) { (_) in
                    action()
                })
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { (_) in })
            
            controller.presentViewController(alert, animated: true, completion: nil)
    }
    
    class func showImagePicker(
        onController controller: UIViewController!,
        withImageSourceType sourceType: UIImagePickerControllerSourceType!,
        withImagePickerDelegate delegate:
        protocol<UIImagePickerControllerDelegate, UINavigationControllerDelegate>?) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = sourceType
            imagePicker.delegate = delegate
            controller.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    class func displayOrHideTabbar(
        onController controller: UIViewController!,
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