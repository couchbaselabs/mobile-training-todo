//
//  Config.swift
//  Todo
//
//  Created by Jayahari Vavachan on 3/25/21.
//  Copyright © 2021 Couchbase. All rights reserved.
//

import Foundation

// Initial states
fileprivate let kSyncEndpoint = "ws://localhost:4984/todo"
fileprivate let kLoggingEnabled = true
fileprivate let kLoginFlowEnabled = true
fileprivate let kSyncEnabled = true
fileprivate let kSyncWithPushNotification = true

fileprivate let kCCREnabled = false
fileprivate let kCCRType: CCRType = .remote

// Replicator retry logic
fileprivate let kMaxRetry = 9
fileprivate let kMaxRetryWaitTime = 300.0

class Config {
    // MARK: Props
    public private(set) var loggingEnabled: Bool
    public private(set) var loginFlowEnabled: Bool
    public private(set) var syncEnabled: Bool
    public private(set) var ccrEnabled: Bool
    public private(set) var ccrType: CCRType
    public private(set) var pushNotificationEnabled: Bool
    public private(set) var maxAttempts: UInt
    public private(set) var maxAttemptWaitTime: TimeInterval
    
    // can be set from outside
    public var syncURL: String
    
    public static var shared: Config {
        return Config()
    }
    
    // MARK: Lifecycle
    
    private init() {
        syncURL = kSyncEndpoint
        
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: HAS_SETTINGS_KEY) {
            defaults.set(true, forKey: HAS_SETTINGS_KEY)
            defaults.set(kLoggingEnabled, forKey: IS_LOGGING_KEY)
            defaults.set(kLoginFlowEnabled, forKey: IS_LOGIN_FLOW_KEY)
            defaults.set(kSyncEnabled, forKey: IS_SYNC_KEY)
            defaults.set(kSyncWithPushNotification, forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
            defaults.set(kCCREnabled, forKey: IS_CCR_ENABLED_KEY)
            defaults.set(kCCRType.rawValue, forKey: CCR_TYPE_KEY)
            defaults.set(kMaxRetry, forKey: MAX_RETRY_KEY)
            defaults.set(kMaxRetryWaitTime, forKey: MAX_RETRY_WAIT_TIME_KEY)
        }
        
        loggingEnabled = defaults.bool(forKey: IS_LOGGING_KEY)
        loginFlowEnabled = defaults.bool(forKey: IS_LOGIN_FLOW_KEY)
        syncEnabled = defaults.bool(forKey: IS_SYNC_KEY)
        pushNotificationEnabled = defaults.bool(forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
        ccrEnabled = defaults.bool(forKey: IS_CCR_ENABLED_KEY)
        ccrType = CCRType(rawValue: defaults.integer(forKey: CCR_TYPE_KEY))!
        maxAttempts = UInt(defaults.integer(forKey: MAX_RETRY_KEY))
        maxAttemptWaitTime = defaults.double(forKey: MAX_RETRY_WAIT_TIME_KEY)
    }
    
}
