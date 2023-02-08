//
// AppDelegate.swift
//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import UserNotifications
import CouchbaseLiteSwift

// QE:
let kQEFeaturesEnabled = true

// Logout Method
enum LogoutMethod {
    case closeDatabase, deleteDatabase;
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, LoginViewControllerDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        if Config.shared.loggingEnabled {
            Database.log.console.level = .info
        }
        showLogin(username: nil)
        return true
    }
    
    // MARK: - Session
    
    func startSession(username: String, withPassword password: String) throws {
        Session.username = username
        Session.password = password
        
        try DB.shared.open()
        
        DB.shared.startReplicator { change in
            let s = change.status
            self.updateReplicatorStatus(s.activity)
            
            let e = change.status.error as NSError?
            if let code = e?.code, code == 401 {
                Ui.showMessage(on: self.window!.rootViewController!,
                               title: "Authentication Error",
                               message: "Your username or password is not correct",
                               error: nil,
                               onClose: {
                                self.logout(method: .closeDatabase)
                })
            }
        }
        
        registerPushNotification()
        
        showApp()
    }
    
    func showApp() {
        guard let root = window?.rootViewController, let storyboard = root.storyboard else {
            return
        }
        
        let controller = storyboard.instantiateInitialViewController()
        window!.rootViewController = controller
    }
    
    // MARK: - Login
    
    func showLogin(username: String? = nil) {
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
                try DB.shared.close()
            } catch let error as NSError {
                NSLog("Cannot close database: %@", error)
                return
            }
        } else if method == .deleteDatabase {
            do {
                try DB.shared.delete()
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
        showLogin(username: oldUsername)
    }
    
    // MARK: - LoginViewControllerDelegate
    
    func login(controller: UIViewController, username: String, password: String) {
        do {
            try startSession(username: username, withPassword: password)
        } catch let error as NSError {
            Ui.showMessage(on: controller,
                           title: "Error",
                           message: "Login has an error occurred, code = \(error.code).")
            NSLog("Cannot start a session: %@", error)
        }
    }
    
    // MARK: - Replication Status
    
    func updateReplicatorStatus(_ level: Replicator.ActivityLevel) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = (level == .busy)
        if let vc = (window?.rootViewController as? UINavigationController)?.topViewController as? ListsViewController {
            vc.updateReplicatorStatus(level)
        }
    }
    
    // MARK: Push Notification Sync
    
    func registerPushNotification() {
        guard Config.shared.pushNotificationEnabled else { return }
        UIApplication.shared.registerForRemoteNotifications()
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
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Start single shot replicator:
        DB.shared.startPushNotificationReplicator()
        completionHandler(.newData)
    }
}
