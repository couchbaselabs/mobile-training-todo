//
//  AppDelegate.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//
#import "AppDelegate.h"
#import "CBLLoginViewController.h"
#import "CBLSession.h"
#import "CBLUi.h"
#import <UserNotifications/UserNotifications.h>

#define kLoggingEnabled YES
#define kLoginFlowEnabled YES
#define kSyncEnabled YES
#define kSyncEndpoint @"ws://ec2-18-212-13-240.compute-1.amazonaws.com:4984/todo"
#define kSyncWithPushNotification NO

# pragma mark - Custom conflict resolver
typedef enum: NSUInteger {
    LOCAL = 0,
    REMOTE = 1,
    DELETE = 2
} CCRType;

#define kCCREnabled NO
#define kCCRType 1

@interface TestConflictResolver: NSObject<CBLConflictResolver>
- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithResolver: (CBLDocument* (^)(CBLConflict*))resolver;
@end

#pragma mark - AppDelegate

@interface AppDelegate () <CBLLoginViewControllerDelegate, UNUserNotificationCenterDelegate> {
    CBLReplicator *_replicator;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (kLoggingEnabled) {
        CBLDatabase.log.console.level = kCBLLogLevelVerbose;
    }
    
    if (kLoginFlowEnabled) {
        [self loginWithUsername:nil];
    } else {
        NSError *error;
        if (![self startSession:@"todo" password:nil error:&error]) {
            NSLog(@"Cannot start a session: %@", error);
            return NO;
        }
    }
    return YES;
}

- (BOOL)startSession: (NSString *)username password: (NSString *)password error: (NSError **)error {
    if ([self openDatabase:username error: error]) {
        CBLSession.sharedInstance.username = username;
        CBLSession.sharedInstance.password = password;
        
        id<CBLConflictResolver> resolver = nil;
        if (kCCREnabled) {
            resolver = [[TestConflictResolver alloc] initWithResolver: ^CBLDocument* (CBLConflict* con) {
                switch (kCCRType) {
                    case LOCAL:
                        return con.localDocument;
                    case REMOTE:
                        return con.remoteDocument;
                    case DELETE:
                        return nil;
                }
                return con.remoteDocument;
            }];
        }
        
        [self startReplicator:username password:password resolver: resolver];
        [self showApp];
        [self registerRemoteNotification];
        return YES;
    }
    return NO;
}

- (BOOL)openDatabase: (NSString*)username error: (NSError**)error {
    // TRAINING: Create a database
    NSString *dbName = username;
    _database = [[CBLDatabase alloc] initWithName:dbName error:error];
    if (_database) {
        [self createDatabaseIndex];
        return YES;
    }
    return NO;
}

- (BOOL)closeDatabase: (NSError**)error {
    return [_database close: error];
}

- (BOOL)deleteDatabase: (NSError**)error {
    return [_database delete: error];
}

- (void)createDatabaseIndex {
    NSError *error;
    
    CBLValueIndexItem *type = [CBLValueIndexItem property:@"type"];
    CBLValueIndexItem *name = [CBLValueIndexItem property:@"name"];
    CBLValueIndexItem *taskListId = [CBLValueIndexItem property:@"taskList.id"];
    CBLValueIndexItem *task = [CBLValueIndexItem property:@"task"];
    
    // For task list query:
    id index1 = [CBLIndexBuilder valueIndexWithItems:@[type, name]];
    if (![_database createIndex: index1 withName:@"task-list" error:&error]) {
        NSLog(@"Couldn't create index (type, name): %@", error);
    }
    
    // For tasks query:
    id index2 = [CBLIndexBuilder valueIndexWithItems:@[type, taskListId, task]];
    if (!![_database createIndex: index2 withName:@"tasks" error:&error]) {
        NSLog(@"Cannot create index (type, taskList.id, task): %@", error);
    }
}

// TODO handleAccessChange

#pragma mark - Login

- (void)loginWithUsername:(NSString *)username {
    UIStoryboard* storyboard = self.window.rootViewController.storyboard;
    UINavigationController *navigation =
        [storyboard instantiateViewControllerWithIdentifier: @"LoginNavigationController"];
    CBLLoginViewController *loginController = (CBLLoginViewController *)navigation.topViewController;
    loginController.delegate = self;
    loginController.username = username;
    self.window.rootViewController = navigation;
}

- (void)logout: (CBLLogoutMethod)method {
    if (!kLoginFlowEnabled)
        return;
    
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    if (method == CBLLogoutModeCloseDatabase) {
        NSError *error;
        if (![self closeDatabase: &error]) {
            NSLog(@"Cannot close database: %@", error);
            return;
        }
    } else if (method == CBLLogoutModeDeleteDatabase) {
        NSError *error;
        if (![self deleteDatabase: &error]) {
            NSLog(@"Cannot delete database: %@", error);
            return;
        }
    }
    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"Logout took %f seconds", (endTime - startTime));
    
    NSString *oldUsername = [CBLSession sharedInstance].username;
    CBLSession.sharedInstance.username = nil;
    CBLSession.sharedInstance.password = nil;
    [self loginWithUsername:oldUsername];
}

- (void)showApp {
    UIStoryboard* storyboard = self.window.rootViewController.storyboard;
    UIViewController* controller = [storyboard instantiateInitialViewController];
    self.window.rootViewController = controller;
}

#pragma mark - CBLLoginViewControllerDelegate

- (void)login:(CBLLoginViewController *)controller
 withUsername:(NSString *)username
     password:(NSString *)password
{
    [self processLogin:controller withUsername:username password:password];
}

- (void)processLogin:(CBLLoginViewController*)controller
        withUsername:(NSString *)username
            password:(NSString *)password
{
    NSError *error;
    if (![self startSession:username password:password error: &error]) {
        [CBLUi showMessageOn:controller
                       title:@"Error"
                     message:@"Login has an error occurred."
                       error:error onClose:nil];
    }
}

#pragma mark - Replication

- (void)startReplicator:(NSString *)username
               password:(NSString *)password
               resolver:(id<CBLConflictResolver>)resolver {
    if (!kSyncEnabled)
        return;
    
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:[NSURL URLWithString:kSyncEndpoint]];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:_database target:target];
    config.continuous = YES;
    config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:username password:password];
    config.conflictResolver = resolver;
    NSLog(@">> Custom Conflict Resolver: Enabled = %d; Type = %d", kCCREnabled, kCCRType);
    
    _replicator = [[CBLReplicator alloc] initWithConfig:config];
    __weak typeof(self) wSelf = self;
    [_replicator addChangeListener:^(CBLReplicatorChange *change) {
        CBLReplicatorStatus *s =  change.status;
        NSError *e = s.error;
        NSLog(@"[Todo] Replicator: %@ %llu/%llu, error: %@",
              [wSelf ativityLevel: s.activity], s.progress.completed, s.progress.total, e);
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible: s.activity == kCBLReplicatorBusy];
        if (e.code == 401) {
            [CBLUi showMessageOn:wSelf.window.rootViewController
                           title:@"Authentication Error"
                         message:@"Your username or passpword is not correct."
                           error:nil
                         onClose:^{ [wSelf logout: CBLLogoutModeCloseDatabase]; }
             ];
        }

    }];
    [_replicator start];
}

- (void)stopReplicator {
    if (!kSyncEnabled)
        return;

    [_replicator stop];
}

- (NSString *)ativityLevel:(CBLReplicatorActivityLevel)level {
    switch (level) {
        case kCBLReplicatorStopped:
            return @"STOPPED";
        case kCBLReplicatorOffline:
            return @"OFFLINE";
        case kCBLReplicatorConnecting:
            return @"CONNECTING";
        case kCBLReplicatorIdle:
            return @"IDLE";
        case kCBLReplicatorBusy:
            return @"BUSY";
        default:
            return @"UNKNOWN";
    }
}

#pragma mark - Push Notification Sync
    
- (void)registerRemoteNotification {
    if (!kSyncWithPushNotification)
        return;
    
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)
                          completionHandler:
     ^(BOOL granted, NSError * _Nullable error) {
         if (granted) {
             dispatch_async(dispatch_get_main_queue(), ^(void) {
                 [[UIApplication sharedApplication] registerForRemoteNotifications];
             });
         } else {
             NSLog(@"WARNING: Remote Notification has not been authorized");
         }
         if (error) {
             NSLog(@"Register Remote Notification Error: %@", error);
         }
    }];
}
    
- (void)startPushNotificationSync {
    if (!kSyncWithPushNotification)
        return;
    
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:[NSURL URLWithString:kSyncEndpoint]];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:_database target:target];
    CBLSession *session = CBLSession.sharedInstance;
    if (kLoginFlowEnabled && session.username && session.password) {
        config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:session.username password:session.password];
    }
    
    CBLReplicator *repl = [[CBLReplicator alloc] initWithConfig:config];
    __weak typeof(self) wSelf = self;
    [repl addChangeListener:^(CBLReplicatorChange *change) {
        CBLReplicatorStatus *s =  change.status;
        NSError *e = s.error;
        NSLog(@"[Todo] Push-Notification-Replicator: %@ %llu/%llu, error: %@",
              [wSelf ativityLevel: s.activity], s.progress.completed, s.progress.total, e);
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible: s.activity == kCBLReplicatorBusy];
        if (e.code == 401) {
            NSLog(@"ERROR: Authentication Error, username or password is not correct");
        }
    }];
    [repl start];
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
    [self startPushNotificationSync];
    completionHandler(UIBackgroundFetchResultNewData);
}

@end

#pragma mark - CCR Helper class

@implementation TestConflictResolver {
    CBLDocument* (^_resolver)(CBLConflict*);
}

- (instancetype) initWithResolver: (CBLDocument* (^)(CBLConflict*))resolver {
    self = [super init];
    if (self) {
        _resolver = resolver;
    }
    return self;
}

- (CBLDocument *) resolve:(CBLConflict *)conflict {
    return _resolver(conflict);
}

@end
