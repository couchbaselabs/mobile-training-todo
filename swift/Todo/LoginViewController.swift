//
//  LoginViewController.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/12/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import FBSDKLoginKit

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addFBLogin()
    }
    
    // MARK: Facebook Login
    
    func addFBLogin() {
        
        // create the login button
        let fbLoginButton = FBSDKLoginButton()
        fbLoginButton.readPermissions = ["public_profile"]
        fbLoginButton.delegate = self as FBSDKLoginButtonDelegate
        view.addSubview(fbLoginButton)
        
        // position the login button with constraints
        fbLoginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: fbLoginButton,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: view,
                           attribute: .centerX,
                           multiplier: 1.0,
                           constant: 0.0).isActive = true
        fbLoginButton.widthAnchor.constraint(equalTo: loginButton.widthAnchor,
                                           constant: 0.0).isActive = true
        fbLoginButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor,
                                           constant: 12.0).isActive = true
    }
    
    // MARK : Button Actions
    
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

extension LoginViewController: FBSDKLoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        guard result.isCancelled == false else {
            Ui.showMessage(on: self, title: "Error", message: "User Cancellation. Please try again")
            return
        }
        
        guard error == nil else {
            Ui.showMessage(on: self, title: "Error", message: error.localizedDescription)
            return
        }
        
        guard result.grantedPermissions.contains("public_profile") else {
            Ui.showMessage(on: self, title: "Error", message: "Public profile access permission not granted!")
            return
        }
        
        delegate?.login(controller: self, withUsername: FBSDKAccessToken.current().userID, andPassword: "password")
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        NSLog("Logging out... ")
    }
}
