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
    
    @IBOutlet weak var syncBackground: UIStackView!
    @IBOutlet weak var ccrBackground: UIStackView!
    @IBOutlet weak var maxRetryBackground: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
        
    }
}
