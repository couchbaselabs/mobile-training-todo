//
//  AppDelegate.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit
import UserNotifications
import CouchbaseLiteSwift


// Custom conflict resolver
enum CCRType: Int {
    case local = 0, remote, delete;
}

// Database Encryption:
// Note: changing this value requires to delete the app before rerun:
let kDatabaseEncryptionKey: String? = nil

// QE:
let kQEFeaturesEnabled = true

// Crashlytics:
let kCrashlyticsEnabled = true

// Constants:
let kActivities = ["Stopped", "Offline", "Connecting", "Idle", "Busy"]

// Logout Method
enum LogoutMethod {
    case closeDatabase, deleteDatabase;
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, LoginViewControllerDelegate {
    var window: UIWindow?
    
    var database: Database!
    var replicator: Replicator!
    var changeListener: ListenerToken?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        if Config.shared.loggingEnabled {
            Database.log.console.level = .info
        }
        
        if Config.shared.loginFlowEnabled {
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
        Session.password = password
        
        var resolver: ConflictResolverProtocol?
        if Config.shared.ccrEnabled {
            resolver = TestConflictResolver() { (conflict) -> Document? in
                switch Config.shared.ccrType {
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
        registerRemoteNotification()
    }
    
    func openDatabase(username:String) throws {
        var config = DatabaseConfiguration()
        if let password = kDatabaseEncryptionKey {
            config.encryptionKey = EncryptionKey.password(password)
        }
        database = try Database(name: username, config: config)
        createDatabaseIndex()
    }

    func closeDatabase() throws {
        try database.close()
    }
    
    func deleteDatabase() throws {
        try database.delete()
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
    
    func logout(method: LogoutMethod) {
        let startTime = Date().timeIntervalSinceReferenceDate
        if method == .closeDatabase {
            do {
                try closeDatabase()
            } catch let error as NSError {
                NSLog("Cannot close database: %@", error)
                return
            }
        } else if method == .deleteDatabase {
            do {
                try deleteDatabase()
            } catch let error as NSError {
                NSLog("Cannot delete database: %@", error)
                return
            }
        }
        let endTime = Date().timeIntervalSinceReferenceDate
        NSLog("Logout took in \(endTime - startTime) seconds")
        
        let oldUsername = Session.username
        Session.username = nil
        Session.password = nil
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
        guard Config.shared.syncEnabled else {
            return
        }
        
        let auth = Config.shared.loginFlowEnabled ? BasicAuthenticator(username: username, password: password!) : nil
        let target = URLEndpoint(url: URL(string: Config.shared.syncURL)!)
        var config = ReplicatorConfiguration(database: database, target: target)
        config.continuous = true
        config.authenticator = auth
        config.conflictResolver = resolver
        NSLog(">> Custom Conflict Resolver: Enabled = \(Config.shared.ccrEnabled); Type = \(Config.shared.ccrType)")
        config.maxAttempts = Config.shared.maxAttempts
        config.maxAttemptWaitTime = Config.shared.maxAttemptWaitTime
        
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
                                    self.logout(method: .closeDatabase)
                    })
                }
            }
            
            // update the title color to reflect the status
            self.updateReplicatorStatus(s.activity)
        })
        replicator.start()
    }
    
    func updateReplicatorStatus(_ level: Replicator.ActivityLevel) {
        if let vc = (window?.rootViewController as? UINavigationController)?.topViewController as? ListsViewController {
            vc.updateReplicatorStatus(level)
        }
    }
    
    func stopReplication() {
        guard Config.shared.syncEnabled else {
            return
        }
        
        replicator.stop()
        replicator.removeChangeListener(withToken: changeListener!)
        changeListener = nil
    }
    
    // MARK: Push Notification Sync
    
    func registerRemoteNotification() {
        guard Config.shared.pushNotificationEnabled else {
            return
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func startPushNotificationSync() {
        guard Config.shared.pushNotificationEnabled else {
            return
        }
        
        NSLog("[Todo] Start Push Notification ...")
        
        let target = URLEndpoint(url: URL(string: Config.shared.syncURL)!)
        var config = ReplicatorConfiguration(database: database, target: target)
        if Config.shared.loginFlowEnabled, let u = Session.username, let p = Session.password {
            config.authenticator = BasicAuthenticator(username: u, password: p)
        }
        
        let repl = Replicator(config: config)
        changeListener = repl.addChangeListener({ (change) in
            let s = change.status
            let activity = kActivities[Int(s.activity.rawValue)]
            let e = change.status.error as NSError?
            let error = e != nil ? ", error: \(e!.description)" : ""
            NSLog("[Todo] Push-Notification-Replicator: \(activity), \(s.progress.completed)/\(s.progress.total)\(error)")
            UIApplication.shared.isNetworkActivityIndicatorVisible = (s.activity == .busy)
            if let code = e?.code {
                if code == 401 {
                    NSLog("ERROR: Authentication Error, username or password is not correct");
                }
            }
        })
        repl.start()
    }
    
    // MARK: UNUserNotificationCenterDelegate
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Note: Normally the application will send the device token to
        // the backend server so that the backend server can use that to
        // send the push notification to the application. We are just printing
        // to the console here.
        let tokenStrs = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenStrs.joined()
        NSLog("Push Notification Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("WARNING: Failed to register for the remote notification: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Start single shot replicator:
        self.startPushNotificationSync()
        
        completionHandler(.newData)
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
