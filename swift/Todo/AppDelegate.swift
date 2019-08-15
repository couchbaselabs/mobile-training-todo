//
//  AppDelegate.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift
import Fabric
import Crashlytics


// Configuration:
let kLoggingEnabled = true
let kLoginFlowEnabled = true
let kSyncEnabled = true
let kSyncEndpoint = "ws://localhost:4984/todo"

// Custom conflict resolver
enum CCRType {
    case local, remote, delete;
}
let kCCREnabled = false
let kCCRType: CCRType = .remote

// Crashlytics:
let kCrashlyticsEnabled = true

// Constants:
let kActivities = ["Stopped", "Offline", "Connecting", "Idle", "Busy"]

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginViewControllerDelegate {
    var window: UIWindow?
    
    var database: Database!
    var replicator: Replicator!
    var changeListener: ListenerToken?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        initCrashlytics()
        
        if kLoggingEnabled {
            Database.log.console.level = .verbose
        }
        
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
        
        var resolver: ConflictResolverProtocol?
        if kCCREnabled {
            resolver = TestConflictResolver() { (conflict) -> Document? in
                switch kCCRType {
                case .local:
                    return conflict.localDocument
                case .remote:
                    return conflict.remoteDocument
                case .delete:
                    return nil;
                }
            }
        }
        
        startReplication(withUsername: username, password: password, resolver: resolver)
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
        let type = ValueIndexItem.expression(Expression.property("type"))
        let name = ValueIndexItem.expression(Expression.property("name"))
        let taskListId = ValueIndexItem.expression(Expression.property("taskList.id"))
        let task = ValueIndexItem.expression(Expression.property("task"))
        
        do {
            let index = IndexBuilder.valueIndex(items: type, name)
            try database.createIndex(index, withName: "task-list")
        } catch let error as NSError {
            NSLog("Couldn't create index (type, name): %@", error);
        }
        
        // For tasks query:
        do {
            let index = IndexBuilder.valueIndex(items: type, taskListId, task)
            try database.createIndex(index, withName: "tasks")
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
    
    func startReplication(withUsername username:String, password:String? = "", resolver: ConflictResolverProtocol?) {
        guard kSyncEnabled else {
            return
        }
        
        let auth = kLoginFlowEnabled ? BasicAuthenticator(username: username, password: password!) : nil
        let target = URLEndpoint(url: URL(string: kSyncEndpoint)!)
        let config = ReplicatorConfiguration(database: database, target: target)
        config.continuous = true
        config.authenticator = auth
        config.conflictResolver = resolver
        NSLog(">> Custom Conflict Resolver: Enabled = \(kCCREnabled); Type = \(kCCRType)")
        
        replicator = Replicator(config: config)
        changeListener = replicator.addChangeListener({ (change) in
            let s = change.status
            let activity = kActivities[Int(s.activity.rawValue)]
            let e = change.status.error as NSError?
            let error = e != nil ? ", error: \(e!.description)" : ""
            NSLog("[Todo] Replicator: \(activity), \(s.progress.completed)/\(s.progress.total)\(error)")
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
        replicator.removeChangeListener(withToken: changeListener!)
        changeListener = nil
    }
    
    // MARK: Crashlytics
    
    func initCrashlytics() {
        if !kCrashlyticsEnabled {
            return
        }
        
        Fabric.with([Crashlytics.self])
        
        if let info = Bundle(for: Database.self).infoDictionary {
            if let version = info["CFBundleShortVersionString"] {
                Crashlytics.sharedInstance().setObjectValue(version, forKey: "Version")
            }
            
            if let build = info["CFBundleShortVersionString"] {
                Crashlytics.sharedInstance().setObjectValue(build, forKey: "Build")
            }
        }
    }
}

class TestConflictResolver: ConflictResolverProtocol {
    let _resolver: (Conflict) -> Document?
    
    init(_ resolver: @escaping (Conflict) -> Document?) {
        _resolver = resolver
    }
    
    func resolve(conflict: Conflict) -> Document? {
        return _resolver(conflict)
    }
}
