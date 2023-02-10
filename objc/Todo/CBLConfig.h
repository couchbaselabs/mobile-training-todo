//
// CBLConfig.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define HAS_SETTINGS_KEY                    @"settings.hasSettings"
#define IS_LOGGING_KEY                      @"settings.isLoggingEnabled"
#define IS_SYNC_KEY                         @"settings.isSyncEnabled"
#define IS_PUSH_NOTIFICATION_ENABLED_KEY    @"settings.isPushNotificationEnabled"
#define IS_CCR_ENABLED_KEY                  @"settings.isCCREnabled"
#define CCR_TYPE_KEY                        @"settings.ccrType"
#define MAX_RETRY_KEY                       @"setting.maxRetry"
#define MAX_RETRY_WAIT_TIME_KEY             @"setting.maxRetryWaitTime"
#define SYNC_ENDPOINT                       @"setting.syncEndpoint"

typedef NS_ENUM(NSInteger, CCRType) {
    CCRTypeLocal = 0,
    CCRTypeRemote,
    CCRTypeDelete
};

@interface CBLConfig : NSObject

@property(nonatomic) NSString* syncEndpoint;
@property(nonatomic) BOOL loggingEnabled;
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
