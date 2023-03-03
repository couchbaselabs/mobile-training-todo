//
//  AppController.swift
//  Todo
//
//  Created by Callum Birks on 15/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import os
import SwiftUI
import CouchbaseLiteSwift

// Logout Method
enum LogoutMethod {
    case closeDatabase, deleteDatabase;
}

class AppController {
    public static let logger = Logger()
    
    /// This function doesn't do the real authentication with SG. If the authentication fails, the
    /// app can still be using but there will be no replication.
    public static func login(_ username: String, _ password: String) throws {
        Session.shared.start(username, password)
        
        try DB.shared.open()
        
        DB.shared.startReplicator { change in           
            if let err = change.status.error as NSError?,
               err.code == 401 { // 401 Unauthorized
                logger.log("Authentication error when starting session: \(err.localizedDescription)")
            }
        }
        
        registerPushNotification()
    }
    
    public static func logout(method: LogoutMethod) {
        let startTime = Date().timeIntervalSinceReferenceDate
        if method == .closeDatabase {
            do {
                try DB.shared.close()
            } catch let error as NSError {
                logger.log("Cannot close database: \(error.localizedDescription)")
                return
            }
        } else if method == .deleteDatabase {
            do {
                try DB.shared.delete()
            } catch let error as NSError {
                logger.log("Cannot delete database: \(error.localizedDescription)")
                return
            }
        }
        
        let endTime = Date().timeIntervalSinceReferenceDate
        logger.log("Logout took in \(endTime - startTime) seconds")
        
        Session.shared.end()
    }
    
    private static func registerPushNotification() {
        guard Config.shared.pushNotificationEnabled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, err in
            if success {
                logger.log("Successfully registered for push notifications")
            }
            if let err = err {
                logger.log("Failed to register push notifications: \(err.localizedDescription)")
            }
        }
    }
}
