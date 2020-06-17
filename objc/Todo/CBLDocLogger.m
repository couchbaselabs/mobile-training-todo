//
//  CBLDocLogger.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 6/16/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLDocLogger.h"
#import "AppDelegate.h"
#import "CBLConstants.h"

@implementation CBLDocLogger

+ (void)logTaskList:(CBLDocument*)doc inDatabase: (CBLDatabase*)database {
    CBLQuery *q = [CBLQueryBuilder select:@[S_ID]
                                     from:[CBLQueryDataSource database:database]
                                    where:[[TYPE equalTo:[CBLQueryExpression string:@"task"]]
                                           andExpression: [TASK_LIST_ID equalTo:[CBLQueryExpression string: doc.id]]]
                                  orderBy:@[[CBLQueryOrdering expression:CREATED_AT],
                                            [CBLQueryOrdering expression:TASK]]];
    NSError* error;
    NSArray<CBLQueryResult*>* tasks = [[q execute:&error] allResults];
    
    q = [CBLQueryBuilder select:@[S_ID]
     from:[CBLQueryDataSource database:database]
    where:[[TYPE equalTo:[CBLQueryExpression string: @"task-list.user"]]
           andExpression:[TASK_LIST_ID equalTo:[CBLQueryExpression string: doc.id]]]];
    NSArray<CBLQueryResult*>* users = [[q execute:&error] allResults];
    
    NSLog(@">>>>>>>> TASK LIST LOG START <<<<<<<<");
    NSLog(@"Task List Doc: %@", [self taskListBody:doc]);
    NSLog(@"Number of Tasks: %lu", (unsigned long)tasks.count);
    int i = 0;
    for (CBLQueryResult *task in tasks) {
        @autoreleasepool {
            ++i;
            CBLDocument* taskDoc = [database documentWithID:[task stringAtIndex:0]];
            if (!taskDoc) {
                NSLog(@"Task Doc #%d : << N/A >>", i);
            } else {
                NSLog(@"Task Doc #%d : %@", i, [self taskBody:taskDoc]);
            }
        }
    }
    NSLog(@"Number of Users: %lu", (unsigned long)users.count);
    i = 0;
    for (CBLQueryResult *user in users) {
        @autoreleasepool {
            ++i;
            CBLDocument* userDoc = [database documentWithID:[user stringAtIndex:0]];
            if (!userDoc) {
                NSLog(@"User Doc #%d : << N/A >>", i);
            } else {
                NSLog(@"User Doc #%d : %@", i, [self userBody:userDoc]);
            }
        }
    }
    NSLog(@">>>>>>>> TASK LIST LOG END <<<<<<<<");
}

+ (void)logTask:(CBLDocument*)doc {
    NSLog(@">>>>>>>> TASK LOG START <<<<<<<<");
    NSLog(@"Task Doc: %@", [self taskBody:doc]);
    NSLog(@">>>>>>>> TASK LOG END <<<<<<<<");
}

+ (NSDictionary*)taskListBody:(CBLDocument*)taskListDoc {
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithDictionary:[taskListDoc toDictionary]];
    body[@"_id"] = taskListDoc.id;
    return body;
}

+ (NSDictionary*)taskBody:(CBLDocument*)taskDoc {
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithDictionary:[taskDoc toDictionary]];
    body[@"_id"] = taskDoc.id;
    CBLBlob *blob = (CBLBlob *)body[@"image"];
    if (blob)
        body[@"image"] = [blob properties];
    return body;
}

+ (NSDictionary*)userBody:(CBLDocument*)userDoc {
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithDictionary:[userDoc toDictionary]];
    body[@"_id"] = userDoc.id;
    return body;
}

@end
