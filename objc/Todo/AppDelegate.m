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

#define kLoggingEnabled YES
#define kLoginFlowEnabled NO
#define kSyncEnabled NO
#define kSyncEndpoint [[CBLURLEndpoint alloc] initWithHost: @"localhost" port: 4984 path: @"todo" secure: NO]

@interface AppDelegate () <CBLLoginViewControllerDelegate> {
    CBLReplicator *_replicator;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CBLDatabase setLogLevel: kCBLLogLevelDebug domain:kCBLLogDomainAll];
    if (kLoggingEnabled) {
        [CBLDatabase setLogLevel:kCBLLogLevelDebug domain:kCBLLogDomainAll];
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
        [CBLSession sharedInstance].username = username;
        [self startReplicator:username password:password];
        [self showApp];
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

- (void)createDatabaseIndex {
    NSError *error;
    
    CBLValueIndexItem *type = [CBLValueIndexItem property:@"type"];
    CBLValueIndexItem *name = [CBLValueIndexItem property:@"name"];
    CBLValueIndexItem *taskListId = [CBLValueIndexItem property:@"taskList.id"];
    CBLValueIndexItem *task = [CBLValueIndexItem property:@"task"];
    
    // For task list query:
    id index1 = [CBLIndex valueIndexWithItems:@[type, name]];
    if (![_database createIndex: index1 withName:@"task-list" error:&error]) {
        NSLog(@"Couldn't create index (type, name): %@", error);
    }
    
    // For tasks query:
    id index2 = [CBLIndex valueIndexWithItems:@[type, taskListId, task]];
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

- (void)logout {
    [self stopReplicator];
    
    NSError *error;
    if (![self closeDatabase: &error])
        NSLog(@"Cannot close database: %@", error);
    
    NSString *oldUsername = [CBLSession sharedInstance].username;
    [CBLSession sharedInstance].username = nil;
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

- (void)startReplicator:(NSString *)username password:(NSString *)password {
    if (!kSyncEnabled)
        return;
    
    id config = [[CBLReplicatorConfiguration alloc] initWithDatabase:_database
                                                              target:kSyncEndpoint
                                                               block:
                 ^(CBLReplicatorConfigurationBuilder *builder)
    {
        builder.continuous = YES;
        if (kLoginFlowEnabled) {
            builder.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:username
                                                                           password:password];
        }
    }];
    
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
                         onClose:^{
                             [wSelf logout];
                         }];
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

@end
