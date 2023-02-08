//
// LoginViewController.swift
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

protocol LoginViewControllerDelegate {
    func login(controller: UIViewController, username: String, password: String)
}

class LoginViewController: UIViewController {
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var delegate: LoginViewControllerDelegate?
    var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.text = username
    }
    
    @IBAction func loginAction(sender: AnyObject) {
        var username = usernameTextField.text ?? ""
        username = username.trimmingCharacters(in: CharacterSet.whitespaces)
        
        var password = passwordTextField.text ?? ""
        password = password.trimmingCharacters(in: CharacterSet.whitespaces)
        
        if username.isEmpty || password.isEmpty {
            Ui.showMessage(on: self, title: "Error", message: "Username or password cannot be empty")
            return
        }
        
        delegate?.login(controller: self, username: username, password: password)
    }
}
