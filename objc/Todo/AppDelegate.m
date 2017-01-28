//
//  AppDelegate.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "AppDelegate.h"

#define kDatabaseName @"todo"

#define kUserName @"todo"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSError *error;
    _username = kUserName;
    _database = [[CBLDatabase alloc] initWithName: kDatabaseName error: &error];
    if (!_database) {
        NSLog(@"Cannot open the database: %@", error);
        return NO;
    }
    
    [self createDatabaseIndex];
    
    return YES;
}

- (void)createDatabaseIndex {
    NSError *error;
    
    // For task list query:
    if (![_database createIndexOn:@[@"type", @"name"] error:&error])
        NSLog(@"Couldn't create index (type, name): %@", error);
    
    // For tasks query:
    if (![_database createIndexOn:@[@"type", @"taskList.id", @"task"] error:&error])
        NSLog(@"Cannot create index (type, taskList.id, task): %@", error);
}

@end
