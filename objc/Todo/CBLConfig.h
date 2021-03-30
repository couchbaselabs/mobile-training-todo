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
@property(readonly, nonatomic) BOOL loggingEnabled;
@property(readonly, nonatomic) BOOL loginFlowEnabled;
@property(readonly, nonatomic) BOOL syncEnabled;
@property(readonly, nonatomic) BOOL pushNotificationEnabled;
@property(readonly, nonatomic) BOOL ccrEnabled;
@property(readonly, nonatomic) CCRType ccrType;
@property(readonly, nonatomic) NSInteger maxRetries;
@property(readonly, nonatomic) NSInteger maxRetryWaitTime;

+ (CBLConfig*) shared;

- (instancetype) init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
