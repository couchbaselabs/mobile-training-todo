//
//  AppDelegate.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

let kDatabaseName = "todo"
let kUserName = "todo"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    var database: Database!
    let username = kUserName
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Open a database:
        
        do {
            database = try Database(name: kDatabaseName)
        } catch let error as NSError {
            NSLog("Cannot open the database: %@", error);
            return false;
        }
        
        createDatabaseIndex();
        return true
    }
    
    func createDatabaseIndex() {
        // For task list query:
        do {
            try database.createIndex(["type", "name"])
        } catch let error as NSError {
            NSLog("Couldn't create index (type, name): %@", error);
        }
        
        // For tasks query:
        do {
            try database.createIndex(["type", "taskList.id", "task"])
        } catch let error as NSError {
            NSLog("Couldn't create index (type, taskList.id, task): %@", error);
        }
    }
}
