//
//  CBLConfig.m
//  Todo
//
//  Created by Jayahari Vavachan on 3/29/21.
//  Copyright © 2021 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLConfig.h"
#import "CBLConstants.h"

#define kLoggingEnabled YES
#define kLoginFlowEnabled YES
#define kSyncEnabled YES
#define kSyncEndpoint @"ws://localhost:4984/todo"
#define kSyncWithPushNotification YES

#define kCCREnabled NO
#define kCCRType 1

#define kMaxRetries 9
#define kMaxRetryWaitTime 300.0

@interface CBLConfig ()
@property(nonatomic) BOOL loggingEnabled;
@property(nonatomic) BOOL loginFlowEnabled;
@property(nonatomic) BOOL syncEnabled;
@property(nonatomic) BOOL pushNotificationEnabled;
@property(nonatomic) BOOL ccrEnabled;
@property(nonatomic) CCRType ccrType;
@property(nonatomic) NSInteger maxAttempts;
@property(nonatomic) NSInteger maxAttemptWaitTime;
@end

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
        self.syncEndpoint = kSyncEndpoint;
        
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey: HAS_SETTINGS_KEY]) {
            [defaults setBool: YES forKey: HAS_SETTINGS_KEY];
            [defaults setBool: kLoggingEnabled forKey: IS_LOGGING_KEY];
            [defaults setBool: kLoginFlowEnabled forKey: IS_LOGIN_FLOW_KEY];
            [defaults setBool: kSyncEnabled forKey: IS_SYNC_KEY];
            [defaults setBool: kSyncWithPushNotification forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
            [defaults setBool: kCCREnabled forKey: IS_CCR_ENABLED_KEY];
            [defaults setInteger: kCCRType forKey: CCR_TYPE_KEY];
            [defaults setInteger: kMaxRetries forKey: MAX_RETRY_KEY];
            [defaults setInteger: kMaxRetryWaitTime forKey: MAX_RETRY_WAIT_TIME_KEY];
        }
        
        self.loggingEnabled = [defaults boolForKey: IS_LOGGING_KEY];
        self.loginFlowEnabled = [defaults boolForKey: IS_LOGIN_FLOW_KEY];
        self.syncEnabled = [defaults boolForKey: IS_SYNC_KEY];
        self.pushNotificationEnabled = [defaults boolForKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
        self.ccrEnabled = [defaults boolForKey: IS_CCR_ENABLED_KEY];
        self.ccrType = [defaults integerForKey: CCR_TYPE_KEY];
        self.maxAttempts = [defaults doubleForKey: MAX_RETRY_KEY];
        self.maxAttemptWaitTime = [defaults doubleForKey: MAX_RETRY_WAIT_TIME_KEY];
        
    }
    return self;
}

@end
