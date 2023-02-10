//
// CBLConfig.m
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

#import "CBLConfig.h"

#define kLoggingEnabled YES
#define kLoginFlowEnabled YES
#define kSyncEnabled YES
#define kSyncEndpoint @"ws://localhost:4984/todo"
#define kSyncWithPushNotification YES

#define kCCREnabled NO
#define kCCRType 1

#define kMaxRetries 9
#define kMaxRetryWaitTime 300.0

@implementation CBLConfig

+ (CBLConfig*) shared {
    static CBLConfig *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _shared = [[self alloc] init]; });
    return _shared;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey: HAS_SETTINGS_KEY]) {
            [defaults setBool: YES forKey: HAS_SETTINGS_KEY];
            [defaults setBool: kLoggingEnabled forKey: IS_LOGGING_KEY];
            [defaults setBool: kSyncEnabled forKey: IS_SYNC_KEY];
            [defaults setBool: kSyncWithPushNotification forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
            [defaults setBool: kCCREnabled forKey: IS_CCR_ENABLED_KEY];
            [defaults setInteger: kCCRType forKey: CCR_TYPE_KEY];
            [defaults setDouble: kMaxRetries forKey: MAX_RETRY_KEY];
            [defaults setDouble: kMaxRetryWaitTime forKey: MAX_RETRY_WAIT_TIME_KEY];
            [defaults setValue: kSyncEndpoint forKey: SYNC_ENDPOINT];
        }
        
        self.syncEndpoint = [defaults valueForKey: SYNC_ENDPOINT];
        self.loggingEnabled = [defaults boolForKey: IS_LOGGING_KEY];
        self.syncEnabled = [defaults boolForKey: IS_SYNC_KEY];
        self.pushNotificationEnabled = [defaults boolForKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
        self.ccrEnabled = [defaults boolForKey: IS_CCR_ENABLED_KEY];
        self.ccrType = [defaults integerForKey: CCR_TYPE_KEY];
        self.maxAttempts = [defaults doubleForKey: MAX_RETRY_KEY];
        self.maxAttemptWaitTime = [defaults doubleForKey: MAX_RETRY_WAIT_TIME_KEY];
    }
    return self;
}

- (void) persist {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: true forKey: HAS_SETTINGS_KEY];
    [defaults setBool: self.loggingEnabled forKey: IS_LOGGING_KEY];
    [defaults setBool: self.syncEnabled forKey: IS_SYNC_KEY];
    [defaults setBool: self.pushNotificationEnabled forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
    [defaults setBool: self.ccrEnabled forKey: IS_CCR_ENABLED_KEY];
    [defaults setInteger: self.ccrType forKey: CCR_TYPE_KEY];
    [defaults setDouble: self.maxAttempts forKey: MAX_RETRY_KEY];
    [defaults setDouble: self.maxAttemptWaitTime forKey: MAX_RETRY_WAIT_TIME_KEY];
    [defaults setValue: self.syncEndpoint forKey: SYNC_ENDPOINT];
}

@end
