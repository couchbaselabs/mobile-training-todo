//
//  TextDialog.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/25/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import Foundation

class TextDialog {
    var title: String?
    var message: String?
    var textFieldConfig: ((UITextField) -> Void)?
    var okButtonTitle: String?
    var okButtonStyle: UIAlertActionStyle?
    var onOkAction: ((String) -> Void)?
    var cancelButtonTitle: String?
    var cancelButtonStyle: UIAlertActionStyle?
    var onCancelAction: (() -> Void)?

    func show(controller: UIViewController) {
        var observer: NSObjectProtocol?
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        // OK:
        let okTitle = okButtonTitle ?? "OK"
        let okStyle = okButtonStyle ?? UIAlertActionStyle.Default
        let okAction = UIAlertAction(title: okTitle, style: okStyle) { _ in
            let textField = alert.textFields![0] as UITextField
            if let curObserver = observer {
                NSNotificationCenter.defaultCenter().removeObserver(curObserver)
            }
            if let action = self.onOkAction, text = textField.text {
                action(text)
            }
        }
        okAction.enabled = false
        alert.addAction(okAction)

        // Cancel:
        let cancelTitle = cancelButtonTitle ?? "Cancel"
        let cancelStyle = cancelButtonStyle ?? UIAlertActionStyle.Cancel
        let cancelAction = UIAlertAction(title: cancelTitle, style: cancelStyle) { _ in
            if let curObserver = observer {
                NSNotificationCenter.defaultCenter().removeObserver(curObserver)
            }
            if let action = self.onCancelAction {
                action()
            }
        }
        alert.addAction(cancelAction)

        // TextField:
        alert.addTextFieldWithConfigurationHandler { textField in
            if let config = self.textFieldConfig {
                config(textField)
            }
            observer =  NSNotificationCenter.defaultCenter().addObserverForName(
                UITextFieldTextDidChangeNotification,
                object: textField,
                queue: NSOperationQueue.mainQueue()) { note in
                    okAction.enabled = textField.text != ""
            }
        }

        // Workaround for UICollectionViewFlowLayout is not defined warning:
        alert.view.setNeedsLayout()
        controller.presentViewController(alert, animated: true, completion: nil)
    }
}