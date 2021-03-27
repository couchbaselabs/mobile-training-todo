//
//  SettingsViewController.swift
//  Todo
//
//  Created by Jayahari Vavachan on 3/25/21.
//  Copyright © 2021 Couchbase. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var syncEndpoint: UITextField!
    @IBOutlet weak var loggingSwitch: UISwitch!
    @IBOutlet weak var loginFlowSwitch: UISwitch!
    @IBOutlet weak var syncSwitch: UISwitch!
    @IBOutlet weak var pushNotificationSwitch: UISwitch!
    @IBOutlet weak var ccrSwitch: UISwitch!
    @IBOutlet weak var ccrSegmentControl: UISegmentedControl!
    @IBOutlet weak var maxRetries: UITextField!
    @IBOutlet weak var maxRetryWaitTime: UITextField!
    
    @IBOutlet weak var syncBackground: UIStackView!
    @IBOutlet weak var ccrBackground: UIStackView!
    @IBOutlet weak var maxRetryBackground: UIStackView!
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
        
        setupUI()
        loadSavedValues()
    }
    
    deinit {
      NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Delegates
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y = keyboardSize.height * 2 - self.view.frame.height
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.origin.y += keyboardSize.height
        }
    }
    
    // MARK: Button Actions
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
        let defaults = UserDefaults.standard
        
        defaults.set(true, forKey: HAS_SETTINGS_KEY)
        
        defaults.set(loggingSwitch.isOn, forKey: IS_LOGGING_KEY)
        defaults.set(loginFlowSwitch.isOn, forKey: IS_LOGIN_FLOW_KEY)
        defaults.set(syncSwitch.isOn, forKey: IS_SYNC_KEY)
        defaults.set(pushNotificationSwitch.isOn, forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
        defaults.set(ccrSwitch.isOn, forKey: IS_CCR_ENABLED_KEY)
        defaults.set(ccrSegmentControl.selectedSegmentIndex, forKey: CCR_TYPE_KEY)
        defaults.set(maxRetries.text, forKey: MAX_RETRY_KEY)
        defaults.set(maxRetryWaitTime.text, forKey: MAX_RETRY_WAIT_TIME_KEY)
        
        if let url = syncEndpoint.text {
            Config.shared.syncURL = url
        }
        
        dismiss(animated: true) {
            let app = UIApplication.shared.delegate as! AppDelegate
            app.logout(method: .closeDatabase)
        }
    }
    
    // MARK: Helper methods
    
    func setupUI() {
        syncBackground.layer.borderColor = UIColor.black.cgColor
        syncBackground.layer.borderWidth = 0.1
        syncBackground.layer.cornerRadius = 5;
        ccrBackground.layer.borderColor = UIColor.black.cgColor
        ccrBackground.layer.borderWidth = 0.1
        ccrBackground.layer.cornerRadius = 5;
        maxRetryBackground.layer.borderColor = UIColor.black.cgColor
        maxRetryBackground.layer.borderWidth = 0.1
        maxRetryBackground.layer.cornerRadius = 5;
    }
    
    func loadSavedValues() {
        let defaults = UserDefaults.standard
        if (defaults.bool(forKey: HAS_SETTINGS_KEY)) {
            loggingSwitch.isOn = defaults.bool(forKey: IS_LOGGING_KEY)
            loginFlowSwitch.isOn = defaults.bool(forKey: IS_LOGIN_FLOW_KEY)
            syncSwitch.isOn = defaults.bool(forKey: IS_SYNC_KEY)
            pushNotificationSwitch.isOn = defaults.bool(forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
            ccrSwitch.isOn = defaults.bool(forKey: IS_CCR_ENABLED_KEY)
            ccrSegmentControl.selectedSegmentIndex = defaults.integer(forKey: CCR_TYPE_KEY)
            maxRetries.text = defaults.string(forKey: MAX_RETRY_KEY)
            maxRetryWaitTime.text = defaults.string(forKey: MAX_RETRY_WAIT_TIME_KEY)
            
            // not saved in user defaults
            syncEndpoint.text = Config.shared.syncURL
        } else {
            fatalError("failed to load default settings")
        }
    }
}
