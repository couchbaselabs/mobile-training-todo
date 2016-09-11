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
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // OK:
        let okTitle = okButtonTitle ?? "OK"
        let okStyle = okButtonStyle ?? UIAlertActionStyle.default
        let okAction = UIAlertAction(title: okTitle, style: okStyle) { _ in
            let textField = alert.textFields![0] as UITextField
            if let curObserver = observer {
                NotificationCenter.default.removeObserver(curObserver)
            }
            if let action = self.onOkAction, let text = textField.text {
                action(text)
            }
        }
        okAction.isEnabled = false
        alert.addAction(okAction)

        // Cancel:
        let cancelTitle = cancelButtonTitle ?? "Cancel"
        let cancelStyle = cancelButtonStyle ?? UIAlertActionStyle.cancel
        let cancelAction = UIAlertAction(title: cancelTitle, style: cancelStyle) { _ in
            if let curObserver = observer {
                NotificationCenter.default.removeObserver(curObserver)
            }
            if let action = self.onCancelAction {
                action()
            }
        }
        alert.addAction(cancelAction)

        // TextField:
        alert.addTextField { textField in
            if let config = self.textFieldConfig {
                config(textField)
            }
            observer =  NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UITextFieldTextDidChange,
                object: textField,
                queue: OperationQueue.main) { note in
                    okAction.isEnabled = textField.text != ""
            }
        }

        // Workaround for UICollectionViewFlowLayout is not defined warning:
        alert.view.setNeedsLayout()
        controller.present(alert, animated: true, completion: nil)
    }
}
