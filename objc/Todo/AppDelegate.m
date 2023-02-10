//
// AppDelegate.m
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

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import "CBLConfig.h"
#import "CBLDB.h"
#import "CBLSession.h"
#import "CBLUi.h"
#import "CBLListsViewController.h"
#import "CBLLoginViewController.h"

#pragma mark - AppDelegate

@interface AppDelegate () <CBLLoginViewControllerDelegate, UNUserNotificationCenterDelegate> { }

@end

@implementation AppDelegate

- (BOOL) application: (UIApplication*)application didFinishLaunchingWithOptions: (NSDictionary*)launchOptions {
    if ([CBLConfig shared].loggingEnabled) {
        CBLDatabase.log.console.level = kCBLLogLevelVerbose;
    }
    [self showLoginWithUsername: nil];
    return YES;
}

- (BOOL) startSession: (NSString *)username password: (NSString *)password error: (NSError **)error {
    CBLSession.sharedInstance.username = username;
    CBLSession.sharedInstance.password = password;
    
    if (![CBLDB.shared open: error]) {
        return false;
    }
    
    __weak typeof(self) wSelf = self;
    [CBLDB.shared startReplicator:^(CBLReplicatorChange* change) {
        CBLReplicatorStatus* s = change.status;
        [wSelf updateReplicatorStatus: s.activity];
        if (s.error.code == 401) {
            [CBLUi showMessageOn: wSelf.window.rootViewController
                           title: @"Authentication Error"
                         message: @"Your username or passpword is not correct."
                           error: nil
                         onClose: ^{ [wSelf logout: CBLLogoutModeCloseDatabase]; }
             ];
        }
    }];
    
    [self registerRemoteNotification];
    [self showApp];
    
    return true;
}

#pragma mark - Login

- (void) showLoginWithUsername: (NSString *)username {
    UIStoryboard* storyboard = self.window.rootViewController.storyboard;
    UINavigationController* navigation =
        [storyboard instantiateViewControllerWithIdentifier: @"LoginNavigationController"];
    CBLLoginViewController* loginController = (CBLLoginViewController*)navigation.topViewController;
    loginController.delegate = self;
    loginController.username = username;
    self.window.rootViewController = navigation;
}

- (void) logout: (CBLLogoutMethod)method {
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    if (method == CBLLogoutModeCloseDatabase) {
        NSError* error;
        if (![CBLDB.shared close: &error]) {
            NSLog(@"Cannot close database: %@", error);
            return;
        }
    } else if (method == CBLLogoutModeDeleteDatabase) {
        NSError* error;
        if (![CBLDB.shared delete: &error]) {
            NSLog(@"Cannot delete database: %@", error);
            return;
        }
    }
    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"Logout took %f seconds", (endTime - startTime));
    
    NSString *oldUsername = [CBLSession sharedInstance].username;
    CBLSession.sharedInstance.username = nil;
    CBLSession.sharedInstance.password = nil;
    [self showLoginWithUsername: oldUsername];
}

- (void) showApp {
    UIStoryboard* storyboard = self.window.rootViewController.storyboard;
    UIViewController* controller = [storyboard instantiateInitialViewController];
    self.window.rootViewController = controller;
}

#pragma mark - CBLLoginViewControllerDelegate

- (void) login: (CBLLoginViewController*)controller username: (NSString*)username password: (NSString*)password {
    NSError* error;
    if (![self startSession: username password:password error: &error]) {
        [CBLUi showMessageOn: controller
                       title: @"Error"
                     message: @"Login has an error occurred."
                       error: error
                     onClose: nil];
        NSLog(@"Cannot start session: %@", error);
    }
}

#pragma mark - Replication

- (void) updateReplicatorStatus: (CBLReplicatorActivityLevel)level {
    [UIApplication.sharedApplication setNetworkActivityIndicatorVisible: level == kCBLReplicatorBusy];
    id vc = ((UINavigationController*)self.window.rootViewController).topViewController;
    if ([vc isKindOfClass: [CBLListsViewController class]]) {
        [vc updateReplicatorStatus: level];
    }
}

#pragma mark - Push Notification Sync
    
- (void)registerRemoteNotification {
    if (![CBLConfig shared].pushNotificationEnabled) {
        return;
    }
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

#pragma mark - UNUserNotificationCenterDelegate
    
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Note: Normally the application will send the device token to
    // the backend server so that the backend server can use that to
    // send the push notification to the application. We are just printing
    // to the console here.
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Push Notification Device Token: %@", token);
}
    
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"WARNING: Failed to register for the remote notification: %@", error);
}
    
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [CBLDB.shared startPushNotificationReplicator];
    completionHandler(UIBackgroundFetchResultNewData);
}

@end
