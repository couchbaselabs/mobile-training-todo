//
//  CBLConstants.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 8/7/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#ifndef CBLConstants_h
#define CBLConstants_h

#define COMPLETE          [CBLQueryExpression property:@"complete"]
#define CREATED_AT        [CBLQueryExpression property:@"createdAt"]
#define ID                [CBLQueryMeta id]
#define NAME              [CBLQueryExpression property:@"name"]
#define TASK              [CBLQueryExpression property:@"task"]
#define TASK_LIST_ID      [CBLQueryExpression property:@"taskList.id"]
#define TYPE              [CBLQueryExpression property:@"type"]
#define USERNAME          [CBLQueryExpression property:@"username"]

#define S_COUNT           [CBLQuerySelectResult expression:[CBLQueryFunction count:[CBLQueryExpression integer: 1]]]
#define S_ID              [CBLQuerySelectResult expression:ID]
#define S_NAME            [CBLQuerySelectResult expression:NAME]
#define S_TASK            [CBLQuerySelectResult expression:TASK]
#define S_COMPLETE        [CBLQuerySelectResult expression:COMPLETE]
#define S_IMAGE           [CBLQuerySelectResult property: @"image"]
#define S_TASK_LIST_ID    [CBLQuerySelectResult expression:TASK_LIST_ID]
#define S_USERNAME        [CBLQuerySelectResult expression:USERNAME]

// Config Keys

#define HAS_SETTINGS_KEY                    @"settings.hasSettings"
#define IS_LOGGING_KEY                      @"settings.isLoggingEnabled"
#define IS_LOGIN_FLOW_KEY                   @"settings.isLoginFlowEnabled"
#define IS_SYNC_KEY                         @"settings.isSyncEnabled"
#define IS_PUSH_NOTIFICATION_ENABLED_KEY    @"settings.isPushNotificationEnabled"
#define IS_CCR_ENABLED_KEY                  @"settings.isCCREnabled"
#define CCR_TYPE_KEY                        @"settings.ccrType"
#define MAX_RETRY_KEY                       @"setting.maxRetry"
#define MAX_RETRY_WAIT_TIME_KEY             @"setting.maxRetryWaitTime"

#endif /* CBLConstants_h */
