//
// CBLDocLogger.m
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

#import "CBLDocLogger.h"
#import "CBLDB.h"

@implementation CBLDocLogger

+ (void) logTaskList: (NSString*)listID {
    CBLDocument* taskList = [CBLDB.shared getTaskListByID: listID error: nil];
    if (!taskList) {
        NSLog(@"No Task List ID: %@", listID);
        return;
    }
    
    NSArray<CBLQueryResult*>* tasks = [[CBLDB.shared getTasksForTaskListID: listID error: nil] allResults];
    NSArray<CBLQueryResult*>* users = [[CBLDB.shared getSharedUsersForTaskListID: listID error: nil] allResults];
    
    NSLog(@">>>>>>>> TASK LIST LOG START <<<<<<<<");
    NSLog(@"Task List Doc: %@", [self taskListBody: taskList]);
    NSLog(@"Number of Tasks: %lu", (unsigned long)tasks.count);
    int i = 0;
    for (CBLQueryResult* task in tasks) {
        @autoreleasepool {
            ++i;
            NSString* taskID = [task stringAtIndex:0];
            CBLDocument* taskDoc = [CBLDB.shared getTaskByID: taskID error: nil];
            if (!taskDoc) {
                NSLog(@"Task Doc #%d : << N/A >>", i);
            } else {
                NSLog(@"Task Doc #%d : %@", i, [self taskBody:taskDoc]);
            }
        }
    }
    NSLog(@"Number of Users: %lu", (unsigned long)users.count);
    i = 0;
    for (CBLQueryResult* user in users) {
        @autoreleasepool {
            ++i;
            NSString* userID = [user stringAtIndex:0];
            CBLDocument* userDoc = [CBLDB.shared getSharedUserByID: userID error: nil];
            if (!userDoc) {
                NSLog(@"User Doc #%d : << N/A >>", i);
            } else {
                NSLog(@"User Doc #%d : %@", i, [self userBody:userDoc]);
            }
        }
    }
    NSLog(@">>>>>>>> TASK LIST LOG END <<<<<<<<");
}

+ (void) logTask: (NSString*)taskID {
    CBLDocument* doc = [CBLDB.shared getTaskByID: taskID error: nil];
    if (doc) {
        NSLog(@"No Task ID: %@", taskID);
        return;
    }
    NSLog(@">>>>>>>> TASK LOG START <<<<<<<<");
    NSLog(@"Task Doc: %@", [self taskBody: doc]);
    NSLog(@">>>>>>>> TASK LOG END <<<<<<<<");
}

+ (NSDictionary*) taskListBody: (CBLDocument*)taskListDoc {
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithDictionary: [taskListDoc toDictionary]];
    body[@"_id"] = taskListDoc.id;
    return body;
}

+ (NSDictionary*) taskBody: (CBLDocument*)taskDoc {
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithDictionary: [taskDoc toDictionary]];
    body[@"_id"] = taskDoc.id;
    CBLBlob *blob = (CBLBlob *)body[@"image"];
    if (blob)
        body[@"image"] = [blob properties];
    return body;
}

+ (NSDictionary*) userBody: (CBLDocument*)userDoc {
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithDictionary: [userDoc toDictionary]];
    body[@"_id"] = userDoc.id;
    return body;
}

@end
