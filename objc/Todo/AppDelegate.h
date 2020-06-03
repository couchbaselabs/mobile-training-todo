//
//  AppDelegate.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

typedef NS_ENUM(NSInteger, CBLLogoutMethod) {
    CBLLogoutModeCloseDatabase = 0,
    CBLLogoutModeDeleteDatabase
};

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, nonatomic) CBLDatabase *database;
@property (readonly, nonatomic) NSString *username;

- (void)logout: (CBLLogoutMethod)method;

@end

