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

#define S_COUNT           [CBLQuerySelectResult expression:[CBLQueryFunction count:@(1)]]
#define S_ID              [CBLQuerySelectResult expression:ID]
#define S_NAME            [CBLQuerySelectResult expression:NAME]
#define S_TASK_LIST_ID    [CBLQuerySelectResult expression:TASK_LIST_ID]
#define S_USERNAME        [CBLQuerySelectResult expression:USERNAME]

#endif /* CBLConstants_h */
