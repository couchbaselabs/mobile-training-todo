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

// QE:
let kQEFeaturesEnabled = true

// Logout Method
enum LogoutMethod {
    case closeDatabase, deleteDatabase;
}

class AppController {
    public static let logger = Logger()
    
    public static func startSession(_ username: String, _ password: String) throws -> Bool {
        Session.shared.start(username, password)
        
        try DB.shared.open()
        
        var success: Bool = true
        
        DB.shared.startReplicator { change in           
            if let err = change.status.error as NSError?,
               err.code == 401 { // 401 Unauthorized
                success = false
                logger.log("Authentication error when starting session: \(err.localizedDescription)")
            }
        }
        
        registerPushNotification()
        
        return success
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
