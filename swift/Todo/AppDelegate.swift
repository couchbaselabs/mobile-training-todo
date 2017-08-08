//
//  AppDelegate.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

let kLoginFlowEnabled = true
let kSyncEnabled = true
let kSyncGatewayUrl = URL(string: "blip://10.17.6.102:4984/todo")!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginViewControllerDelegate {
    var window: UIWindow?
    
    var database: Database!
    var replicator: Replicator!
    var changeListener: NSObjectProtocol?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        if kLoginFlowEnabled {
            login(username: nil)
        } else {
            do {
                try startSession(username: "todo")
            } catch let error as NSError {
                NSLog("Cannot start a session: %@", error)
                return false
            }
        }
        return true
    }
    
    // MARK: - Session
    
    func startSession(username:String, withPassword password:String? = nil) throws {
        try openDatabase(username: username)
        Session.username = username
        startReplication(withUsername: username, andPassword: password)
        showApp()
    }
    
    func openDatabase(username:String) throws {
        database = try Database(name: username)
        createDatabaseIndex()
    }

    func closeDatabase() throws {
        try database.close()
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
    
    // MARK: - Login
    
    func login(username: String? = nil) {
        let storyboard =  window!.rootViewController!.storyboard
        let navigation = storyboard!.instantiateViewController(
            withIdentifier: "LoginNavigationController") as! UINavigationController
        let loginController = navigation.topViewController as! LoginViewController
        loginController.delegate = self
        loginController.username = username
        window!.rootViewController = navigation
    }
    
    func logout() {
        stopReplication()
        do {
            try closeDatabase()
        } catch let error as NSError {
            NSLog("Cannot close database: %@", error)
        }
        let oldUsername = Session.username
        Session.username = nil
        login(username: oldUsername)
    }
    
    func showApp() {
        guard let root = window?.rootViewController, let storyboard = root.storyboard else {
            return
        }
        
        let controller = storyboard.instantiateInitialViewController()
        window!.rootViewController = controller
    }
    
    // MARK: - LoginViewControllerDelegate
    
    func login(controller: UIViewController, withUsername username: String,
               andPassword password: String) {
        processLogin(controller: controller, withUsername: username, withPassword: password)
    }
    
    func processLogin(controller: UIViewController, withUsername username: String,
                      withPassword password: String) {
        do {
            try startSession(username: username, withPassword: password)
        } catch let error as NSError {
            Ui.showMessage(on: controller,
                           title: "Error",
                           message: "Login has an error occurred, code = \(error.code).")
            NSLog("Cannot start a session: %@", error)
        }
    }
    
    // MARK: - Replication
    
    func startReplication(withUsername username:String, andPassword password:String? = "") {
        guard kSyncEnabled else {
            return
        }
        
        var config = ReplicatorConfiguration(database: database, targetURL: kSyncGatewayUrl)
        config.continuous = true
        if kLoginFlowEnabled {
            config.authenticator = BasicAuthenticator(username: username, password: password!)
        }
        
        replicator = Replicator(config: config)
        changeListener = replicator.addChangeListener({ (change) in
            let s = change.status
            let e = change.status.error as NSError?
            
            NSLog("[Todo] Replicator: \(s.progress.completed)/\(s.progress.total), error: \((e != nil) ? e!.description: "")")
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = (s.activity == .busy)
            if let code = e?.code {
                if code == 401 {
                    Ui.showMessage(on: self.window!.rootViewController!,
                                   title: "Authentication Error",
                                   message: "Your username or password is not correct",
                                   error: nil,
                                   onClose: {
                                    self.logout()
                    })
                }
            }
        })
        replicator.start()
    }
    
    func stopReplication() {
        guard kSyncEnabled else {
            return
        }
        
        replicator.stop()
        replicator.removeChangeListener(changeListener!)
        changeListener = nil
    }
}
