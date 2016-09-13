//
//  TaskTableViewCell.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/9/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var taskLabel: UILabel!
    
    var taskImage: UIImage? {
        didSet {
            imageButton.setImage(taskImage, for: .normal)
        }
    }
    
    var taskImageAction: (() -> ())?
    
    @IBAction func imageButtonAction(sender: AnyObject) {
        if let action = taskImageAction {
            action()
        }
    }
}
