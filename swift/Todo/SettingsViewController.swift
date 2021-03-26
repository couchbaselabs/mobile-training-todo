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
    @IBOutlet weak var pushNotificationSwitch: UISwitch!
    @IBOutlet weak var ccrSwitch: UISwitch!
    @IBOutlet weak var ccrSegmentControl: UISegmentedControl!
    @IBOutlet weak var maxRetries: UITextField!
    @IBOutlet weak var maxRetryWaitTime: UITextField!
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
        
    }
}
