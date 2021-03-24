//
//  TaskDetailViewController.swift
//  Todo
//
//  Created by Jayahari Vavachan on 3/23/21.
//  Copyright © 2021 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class TaskDetailViewController: UIViewController {
    var taskID: String!
    var task: Document!
    var database: Database!
    
    @IBOutlet var taskName: UILabel!
    @IBOutlet var completeSwitch: UISwitch!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var textView: UITextView!
    @IBOutlet var keyTextField: UITextField!
    @IBOutlet var valueTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        database = app.database
        task = database.document(withID: taskID)!
        
        updateUI()
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        updateUI()
    }
    @IBAction func switchChanged(_ sender: Any) {
        updateTask((sender as! UISwitch).isOn, forKey: "complete")
    }
    
    @IBAction func setKeyValue(_ sender: Any) {
        guard let key = keyTextField.text,
              let value = valueTextField.text else {
            return
        }
        
        updateTask(value, forKey: key)
    }
    
    func updateTask(_ value: Any, forKey key: String) {
        let mutableTask = task.toMutable()
        mutableTask.setValue(value, forKey: key)
        try! database.saveDocument(mutableTask)
        
        task = database.document(withID: taskID)
        updateUI()
    }
    
    func updateUI() {
        completeSwitch.isOn = task.boolean(forKey: "complete")
        
        taskName.text = task.string(forKey: "task")
        textView.text = segmentedControl.selectedSegmentIndex == 0
            ? "\(task.toDictionary())" : "\(task.toJSON())" 
    }
}
