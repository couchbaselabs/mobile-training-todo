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

enum CCRType: Int {
    case local = 0, remote, delete;
}

// Constants:
public let HAS_SETTINGS_KEY = "settings.hasSettings"
public let IS_LOGGING_KEY = "settings.isLoggingEnabled"
public let IS_SYNC_KEY = "settings.isSyncEnabled"
public let IS_PUSH_NOTIFICATION_ENABLED_KEY = "settings.isPushNotificationEnabled"
public let IS_CCR_ENABLED_KEY = "settings.isCCREnabled"
public let CCR_TYPE_KEY = "settings.ccrType"
public let MAX_ATTEMPTS_KEY = "setting.maxAttempt"
public let MAX_ATTEMPTS_WAIT_TIME_KEY = "setting.maxAttemptWaitTime"

// Initial states
fileprivate let kSyncEndpoint = "ws://localhost:4984/todo"
fileprivate let kLoggingEnabled = true
fileprivate let kSyncEnabled = true
fileprivate let kSyncWithPushNotification = false

fileprivate let kCCREnabled = false
fileprivate let kCCRType: CCRType = .remote

// Replicator retry logic
fileprivate let kMaxAttempt = 0
fileprivate let kMaxAttemptWaitTime = 0

class Config {
    // MARK: Props
    public private(set) var loggingEnabled: Bool
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
            defaults.set(kSyncEnabled, forKey: IS_SYNC_KEY)
            defaults.set(kSyncWithPushNotification, forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
            defaults.set(kCCREnabled, forKey: IS_CCR_ENABLED_KEY)
            defaults.set(kCCRType.rawValue, forKey: CCR_TYPE_KEY)
            defaults.set(kMaxAttempt, forKey: MAX_ATTEMPTS_KEY)
            defaults.set(kMaxAttemptWaitTime, forKey: MAX_ATTEMPTS_WAIT_TIME_KEY)
        }
        
        loggingEnabled = defaults.bool(forKey: IS_LOGGING_KEY)
        syncEnabled = defaults.bool(forKey: IS_SYNC_KEY)
        pushNotificationEnabled = defaults.bool(forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
        ccrEnabled = defaults.bool(forKey: IS_CCR_ENABLED_KEY)
        ccrType = CCRType(rawValue: defaults.integer(forKey: CCR_TYPE_KEY))!
        maxAttempts = UInt(defaults.integer(forKey: MAX_ATTEMPTS_KEY))
        maxAttemptWaitTime = defaults.double(forKey: MAX_ATTEMPTS_WAIT_TIME_KEY)
    }
}
