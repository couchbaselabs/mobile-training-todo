//
// CBLDB.h
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
#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBLDB : NSObject

+ (instancetype) shared;

- (instancetype) init NS_UNAVAILABLE;

// MARK: Database

- (BOOL) open: (NSError**)error;

- (BOOL) close: (NSError**)error;

- (BOOL) delete: (NSError**)error;

// MARK: Replicator

- (void) startReplicator: (void (^)(CBLReplicatorChange*))listener;

- (void) startPushNotificationReplicator;

// MARK: Lists

- (void) createTaskListWithName: (NSString*)name completion: (void (^)(bool success, NSError* _Nullable error))completion;

- (BOOL) updateTaskListWithID: (NSString*)listID name: (NSString*)name error: (NSError**)error;

- (BOOL) deleteTaskListWithID: (NSString*)listID error: (NSError**)error;

- (nullable CBLDocument*) getTaskListByID: (NSString*)listID error: (NSError**)error;

- (nullable CBLQueryResultSet*) getTaskListsByName: (NSString*)name error: (NSError**)error;

- (nullable CBLQuery*) getTaskListsQuery: (NSError**)error;

- (nullable CBLQuery*) getIncompletedTasksCountsQuery: (NSError**)error;

// MARK: Tasks

- (BOOL) createTaskForTaskList: (CBLDocument*)taskList task: (NSString*)task extra: (nullable NSString*)extra error: (NSError**)error;

- (BOOL) updateTaskWithID: (NSString*)taskID task: (NSString*)task error: (NSError**)error;

- (BOOL) updateTaskWithID: (NSString*)taskID complete: (BOOL)complete error: (NSError**)error;

- (BOOL) updateTaskWithID: (NSString*)taskID image: (nullable UIImage*)image error: (NSError**)error;

- (BOOL) deleteTaskWithID: (NSString*)taskID error: (NSError**)error;

- (nullable CBLDocument*) getTaskByID: (NSString*)taskID error: (NSError**)error;

- (nullable CBLQuery*) getTasksQueryForTaskListID: (NSString*)listID error: (NSError**)error;

- (nullable CBLQueryResultSet*) getTasksForTaskListID: (NSString*)listID error: (NSError**)error;

- (nullable CBLQueryResultSet*) getTasksForTaskListID: (NSString*)listID task: (NSString*)task error: (NSError**)error;

// MARK: Users

- (BOOL) addSharedUserForTaskList: (CBLDocument*)taskList username: (NSString*)username error: (NSError**)error;

- (BOOL) deletedSharedUserWithID: (NSString*)userID error: (NSError**)error;

- (nullable CBLDocument*) getSharedUserByID: (NSString*)userID error: (NSError**)error;

- (nullable CBLQuery*) getSharedUsersQueryForTaskList: (CBLDocument*)taskList error: (NSError**)error;

- (nullable CBLQueryResultSet*) getSharedUsersForTaskListID: (NSString*)listID error: (NSError**)error;

- (nullable CBLQueryResultSet*) getSharedUsersForTaskList: (CBLDocument*)taskList username: (NSString*)username error: (NSError**)error;

@end

NS_ASSUME_NONNULL_END
