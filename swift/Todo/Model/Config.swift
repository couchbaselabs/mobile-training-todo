//
// Config.swift
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

import Foundation

enum CCRType: Int, CaseIterable {
    case local = 0, remote, delete;
    
    func description() -> String {
        switch self {
        case .local:
            return "Local"
        case .remote:
            return "Remote"
        case .delete:
            return "Delete"
        }
    }
}

// Constants:
public let HAS_SETTINGS_KEY = "settings.hasSettings"
public let IS_LOGGING_KEY = "settings.isLoggingEnabled"
public let IS_SYNC_KEY = "settings.isSyncEnabled"
public let SYNC_URL_KEY = "settings.syncURL"
public let SYNC_ADMIN_PORT_KEY = "settings.syncAdminPort"
public let SYNC_ADMIN_USERNAME_KEY = "settings.syncAdminUserName"
public let SYNC_ADMIN_PASSWORD_KEY = "settings.syncAdminPassword"
public let IS_PUSH_NOTIFICATION_ENABLED_KEY = "settings.isPushNotificationEnabled"
public let IS_CCR_ENABLED_KEY = "settings.isCCREnabled"
public let CCR_TYPE_KEY = "settings.ccrType"
public let MAX_ATTEMPTS_KEY = "setting.maxAttempt"
public let MAX_ATTEMPTS_WAIT_TIME_KEY = "setting.maxAttemptWaitTime"

// Initial states
fileprivate let kSyncURL = "ws://localhost:4984/todo"

fileprivate let kSyncAdminPort = 4985
fileprivate let kSyncAdminUsername = "Administrator"
fileprivate let kSyncAdminPassword = "password"      // Do not do this in the actual production app

fileprivate let kLoggingEnabled = true
fileprivate let kSyncEnabled = true
fileprivate let kSyncWithPushNotification = false

fileprivate let kCCREnabled = false
fileprivate let kCCRType: CCRType = .remote

// Replicator retry logic
fileprivate let kMaxAttempt = 0
fileprivate let kMaxAttemptWaitTime = 0.0

class Config {
    // MARK: Props
    
    public var loggingEnabled: Bool
    public var syncEnabled: Bool
    public var syncURL: String
    public var ccrEnabled: Bool
    public var ccrType: CCRType
    public var pushNotificationEnabled: Bool
    public var maxAttempts: UInt
    public var maxAttemptWaitTime: TimeInterval
    
    public var syncAdminPort: Int
    public var syncAdminUsername: String
    public var syncAdminPassword: String
    
    public static let shared = Config()
    
    // MARK: Lifecycle
    
    private init() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: HAS_SETTINGS_KEY) {
            defaults.set(true, forKey: HAS_SETTINGS_KEY)
            defaults.set(kLoggingEnabled, forKey: IS_LOGGING_KEY)
            defaults.set(kSyncEnabled, forKey: IS_SYNC_KEY)
            defaults.set(kSyncURL, forKey: SYNC_URL_KEY)
            defaults.set(kSyncAdminPort, forKey: SYNC_ADMIN_PORT_KEY)
            defaults.set(kSyncAdminUsername, forKey: SYNC_ADMIN_USERNAME_KEY)
            defaults.set(kSyncAdminPassword, forKey: SYNC_ADMIN_PASSWORD_KEY)
            defaults.set(kSyncWithPushNotification, forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
            defaults.set(kCCREnabled, forKey: IS_CCR_ENABLED_KEY)
            defaults.set(kCCRType.rawValue, forKey: CCR_TYPE_KEY)
            defaults.set(kMaxAttempt, forKey: MAX_ATTEMPTS_KEY)
            defaults.set(kMaxAttemptWaitTime, forKey: MAX_ATTEMPTS_WAIT_TIME_KEY)
        }
        
        loggingEnabled = defaults.bool(forKey: IS_LOGGING_KEY)
        syncEnabled = defaults.bool(forKey: IS_SYNC_KEY)
        syncURL = defaults.string(forKey: SYNC_URL_KEY)!
        pushNotificationEnabled = defaults.bool(forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
        ccrEnabled = defaults.bool(forKey: IS_CCR_ENABLED_KEY)
        ccrType = CCRType(rawValue: defaults.integer(forKey: CCR_TYPE_KEY))!
        maxAttempts = UInt(defaults.integer(forKey: MAX_ATTEMPTS_KEY))
        maxAttemptWaitTime = defaults.double(forKey: MAX_ATTEMPTS_WAIT_TIME_KEY)
        
        // SG Admin info:
        syncAdminPort = defaults.integer(forKey: SYNC_ADMIN_PORT_KEY)
        syncAdminUsername = defaults.string(forKey: SYNC_ADMIN_USERNAME_KEY)!
        syncAdminPassword = defaults.string(forKey: SYNC_ADMIN_PASSWORD_KEY)!
    }
    
    public func save() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: HAS_SETTINGS_KEY)
        defaults.set(loggingEnabled, forKey: IS_LOGGING_KEY)
        defaults.set(syncEnabled, forKey: IS_SYNC_KEY)
        defaults.set(syncURL, forKey: SYNC_URL_KEY)
        defaults.set(syncAdminPort, forKey: SYNC_ADMIN_PORT_KEY)
        defaults.set(syncAdminUsername, forKey: SYNC_ADMIN_USERNAME_KEY)
        defaults.set(syncAdminPassword, forKey: SYNC_ADMIN_PASSWORD_KEY)
        defaults.set(pushNotificationEnabled, forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
        defaults.set(ccrEnabled, forKey: IS_CCR_ENABLED_KEY)
        defaults.set(ccrType.rawValue, forKey: CCR_TYPE_KEY)
        defaults.set(maxAttempts, forKey: MAX_ATTEMPTS_KEY)
        defaults.set(maxAttemptWaitTime, forKey: MAX_ATTEMPTS_WAIT_TIME_KEY)
    }
}
