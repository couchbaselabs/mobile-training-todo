//
// TextDialog.swift
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
            observer =  NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange,
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
