//
//  CBLConfig.h
//  Todo
//
//  Created by Jayahari Vavachan on 3/29/21.
//  Copyright © 2021 Pasin Suriyentrakorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface CBLConfig : NSObject

@property(nonatomic) NSString* syncEndpoint;
@property(nonatomic) BOOL loggingEnabled;
@property(nonatomic) BOOL loginFlowEnabled;
@property(nonatomic) BOOL syncEnabled;
@property(nonatomic) BOOL pushNotificationEnabled;
@property(nonatomic) BOOL ccrEnabled;
@property(nonatomic) CCRType ccrType;
@property(nonatomic) NSInteger maxAttempts;
@property(nonatomic) NSInteger maxAttemptWaitTime;

+ (CBLConfig*) shared;

- (instancetype) init NS_UNAVAILABLE;

- (void) persist;

@end

NS_ASSUME_NONNULL_END
