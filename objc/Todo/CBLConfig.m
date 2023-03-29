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
#define kSyncAdminPort 4985
#define kSyncAdminUsername @"admin"
#define kSyncAdminPassword @"password"
#define kSyncWithPushNotification YES

#define kCCREnabled NO
#define kCCRType 1

#define kMaxRetries 9
#define kMaxRetryWaitTime 300.0

#define HAS_SETTINGS_KEY                    @"settings.hasSettings"
#define IS_LOGGING_KEY                      @"settings.isLoggingEnabled"
#define IS_SYNC_KEY                         @"settings.isSyncEnabled"
#define IS_PUSH_NOTIFICATION_ENABLED_KEY    @"settings.isPushNotificationEnabled"
#define IS_CCR_ENABLED_KEY                  @"settings.isCCREnabled"
#define CCR_TYPE_KEY                        @"settings.ccrType"
#define MAX_RETRY_KEY                       @"setting.maxRetry"
#define MAX_RETRY_WAIT_TIME_KEY             @"setting.maxRetryWaitTime"
#define SYNC_ENDPOINT_KEY                   @"setting.syncEndpoint"
#define SYNC_ADMIN_PORT_KEY                 @"setting.syncAdminPort"
#define SYNC_ADMIN_USERNAME_KEY             @"setting.syncAdminUsername"
#define SYNC_ADMIN_PASSWORD_KEY             @"setting.syncAdminPassword"

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
            [defaults setValue: kSyncEndpoint forKey: SYNC_ENDPOINT_KEY];
            [defaults setInteger: kSyncAdminPort forKey: SYNC_ADMIN_PORT_KEY];
            [defaults setValue: kSyncAdminUsername forKey: SYNC_ADMIN_USERNAME_KEY];
            [defaults setValue: kSyncAdminPassword forKey: SYNC_ADMIN_PASSWORD_KEY];
            [defaults setBool: kCCREnabled forKey: IS_CCR_ENABLED_KEY];
            [defaults setInteger: kCCRType forKey: CCR_TYPE_KEY];
            [defaults setDouble: kMaxRetries forKey: MAX_RETRY_KEY];
            [defaults setDouble: kMaxRetryWaitTime forKey: MAX_RETRY_WAIT_TIME_KEY];
        }
        
        self.loggingEnabled = [defaults boolForKey: IS_LOGGING_KEY];
        self.syncEnabled = [defaults boolForKey: IS_SYNC_KEY];
        self.pushNotificationEnabled = [defaults boolForKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
        self.syncEndpoint = [defaults valueForKey: SYNC_ENDPOINT_KEY];
        self.syncAdminPort = [defaults integerForKey: SYNC_ADMIN_PORT_KEY];
        self.syncAdminUsername = [defaults valueForKey: SYNC_ADMIN_USERNAME_KEY];
        self.syncAdminPassword = [defaults valueForKey: SYNC_ADMIN_PASSWORD_KEY];
        self.ccrEnabled = [defaults boolForKey: IS_CCR_ENABLED_KEY];
        self.ccrType = [defaults integerForKey: CCR_TYPE_KEY];
        self.maxAttempts = [defaults doubleForKey: MAX_RETRY_KEY];
        self.maxAttemptWaitTime = [defaults doubleForKey: MAX_RETRY_WAIT_TIME_KEY];
    }
    return self;
}

- (void) save {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: true forKey: HAS_SETTINGS_KEY];
    [defaults setBool: self.loggingEnabled forKey: IS_LOGGING_KEY];
    [defaults setBool: self.syncEnabled forKey: IS_SYNC_KEY];
    [defaults setBool: self.pushNotificationEnabled forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
    [defaults setValue: self.syncEndpoint forKey: SYNC_ENDPOINT_KEY];
    [defaults setInteger: self.syncAdminPort forKey: SYNC_ADMIN_PORT_KEY];
    [defaults setValue: self.syncAdminUsername forKey: SYNC_ADMIN_USERNAME_KEY];
    [defaults setValue: self.syncAdminPassword forKey: SYNC_ADMIN_PASSWORD_KEY];
    [defaults setBool: self.ccrEnabled forKey: IS_CCR_ENABLED_KEY];
    [defaults setInteger: self.ccrType forKey: CCR_TYPE_KEY];
    [defaults setDouble: self.maxAttempts forKey: MAX_RETRY_KEY];
    [defaults setDouble: self.maxAttemptWaitTime forKey: MAX_RETRY_WAIT_TIME_KEY];
}

@end
