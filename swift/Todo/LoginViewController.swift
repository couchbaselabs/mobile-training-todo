//
//  LoginViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/12/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit

protocol LoginViewControllerDelegate {
    func login(controller: UIViewController, withUsername username: String, andPassword: String)
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
        
        delegate?.login(controller: self, withUsername: username, andPassword: password)
    }
}
