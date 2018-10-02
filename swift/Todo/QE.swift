//
//  QE.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 10/1/18.
//  Copyright © 2018 Couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

class QE {
 
    class func generateTasks(database: Database, taskList: Document, numbers: Int, includesPhoto: Bool) {
        for i in 1...numbers {
            autoreleasepool {
                let doc = MutableDocument()
                doc.setValue("task", forKey: "type")
                let taskListInfo = ["id": taskList.id, "owner": taskList.string(forKey: "owner")]
                doc.setValue(taskListInfo, forKey: "taskList")
                doc.setValue(Date(), forKey: "createdAt")
                doc.setValue("Task \(i)", forKey: "task")
                doc.setValue((i % 2) == 0, forKey: "complete")
                if (includesPhoto) {
                    let data = dataFromResource(name: "\(i % 10)", ofType: "JPG") as Data
                    let blob = Blob(contentType: "image/jpeg", data: data)
                    doc.setValue(blob, forKey: "image")
                }
                try! database.saveDocument(doc)
            }
        }
    }
    
    class func dataFromResource(name: String, ofType: String) -> NSData {
        let path = Bundle.main.path(forResource: name, ofType: ofType)
        return try! NSData(contentsOfFile: path!, options: [])
    }
}
