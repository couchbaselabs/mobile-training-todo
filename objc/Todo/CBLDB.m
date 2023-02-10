//
// CBLDB.m
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

#import "CBLDB.h"
#import "CBLConfig.h"
#import "CBLSession.h"

#define $S(FORMAT, ARGS... )  [NSString stringWithFormat: (FORMAT), ARGS]

@interface TestConflictResolver: NSObject<CBLConflictResolver>
- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithResolver: (CBLDocument* (^)(CBLConflict*))resolver;
@end

@interface CBLDB ()

@property (readonly) CBLCollection* taskLists;
@property (readonly) CBLCollection* tasks;
@property (readonly) CBLCollection* users;
@property (readonly) NSString* currentUser;
@property (readonly) CBLDatabase* openedDB;

@end

@implementation CBLDB {
    CBLDatabase* _database;
    CBLReplicator* _replicator;
    id<CBLListenerToken> _replicatorChangeListener;
    id<CBLListenerToken> _pushNotificationReplicatorChangeListener;
    
    CBLCollection* _taskLists;
    CBLCollection* _tasks;
    CBLCollection* _users;
}

+ (instancetype) shared {
    static CBLDB* _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _shared = [[self alloc] init]; });
    return _shared;
}

- (instancetype) init {
    return [super init];
}

// MARK: Database

- (BOOL) open: (NSError**)error {
    assert(!_database);
    _database = [[CBLDatabase alloc] initWithName: [self currentUser] error: error];
    if (!_database) {
        return false;
    }
    
    if (![self.taskLists createIndexWithName: @"lists"
                                      config: [[CBLValueIndexConfiguration alloc] initWithExpression: @[@"name"]]
                                       error: error]) {
        return false;
    }
    
    if (![self.tasks createIndexWithName: @"tasks"
                                  config: [[CBLValueIndexConfiguration alloc] initWithExpression: @[@"taskList.id", @"task"]]
                                   error: error]) {
        return false;
    }
    
    return true;
}

- (BOOL) close: (NSError**)error {
    if (![self.openedDB close: error]) {
        return false;
    }
    return [self reset];
}

- (BOOL) delete: (NSError**)error {
    if (![self.openedDB delete: error]) {
        return false;
    }
    return [self reset];
}

- (CBLDatabase*) openedDB {
    assert(_database);
    return _database;
}

- (BOOL) reset {
    _database = nil;
    _replicator = nil;
    _replicatorChangeListener = nil;
    _pushNotificationReplicatorChangeListener = nil;
    
    _taskLists = nil;
    _tasks = nil;
    _users = nil;
    
    return true;
}

// MARK: User

- (NSString*) currentUser {
    NSString* username = CBLSession.sharedInstance.username;
    assert(username);
    return username;
}

// MARK: Collection

- (CBLCollection*) collection: (NSString*)name {
    CBLCollection* coll = [[self openedDB] createCollectionWithName: name scope: nil error: nil];
    assert(coll);
    return coll;
}

- (CBLCollection*) taskLists {
    if (!_taskLists) {
        _taskLists = [self collection: @"lists"];
    }
    return _taskLists;
}

- (CBLCollection*) tasks {
    if (!_tasks) {
        _tasks = [self collection: @"tasks"];
    }
    return _tasks;
}

- (CBLCollection*) users {
    if (!_users) {
        _users = [self collection: @"users"];
    }
    return _users;
}

// MARK: Replicator

- (void) startReplicator: (void (^)(CBLReplicatorChange*))listener {
    if (!CBLConfig.shared.syncEnabled) return;
    
    CBLReplicatorConfiguration* config = [self replicatorConfigWithContinuous: true];
    _replicator = [[CBLReplicator alloc] initWithConfig: config];
    __weak typeof(self) wSelf = self;
    _replicatorChangeListener = [_replicator addChangeListener: ^(CBLReplicatorChange *change) {
        CBLReplicatorStatus* s =  change.status;
        NSLog(@"[Todo] Replicator: %@ %llu/%llu, error: %@",
              [wSelf ativityLevel: s.activity], s.progress.completed, s.progress.total, s.error);
        listener(change);
    }];
    [_replicator start];
}

- (void) startPushNotificationReplicator {
    if (!CBLConfig.shared.syncEnabled) return;
    
    NSLog(@"[Todo] Start Background Replication ...");
    if (!_database) {
        // Note : If the app is re-launched in the backgroud, there is no active user logged in.
        // We may implement auto-login in the future but right now this is not supported.
        NSLog(@"[Todo] Skipped Backgrund Replication as No Active Database Opened ...");
        return;
    }
    
    CBLReplicatorConfiguration* config = [self replicatorConfigWithContinuous: false];
    _replicator = [[CBLReplicator alloc] initWithConfig: config];
    __weak typeof(self) wSelf = self;
    _replicatorChangeListener = [_replicator addChangeListener: ^(CBLReplicatorChange *change) {
        CBLReplicatorStatus* s =  change.status;
        NSLog(@"[Todo] Push-Notification-Replicator: %@ %llu/%llu, error: %@",
              [wSelf ativityLevel: s.activity], s.progress.completed, s.progress.total, s.error);
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible: s.activity == kCBLReplicatorBusy];
        if (s.error.code == 401) {
            NSLog(@"ERROR: Authentication Error, username or password is not correct");
        }
    }];
    [_replicator start];
}

- (CBLReplicatorConfiguration*) replicatorConfigWithContinuous: (BOOL)continuous {
    id<CBLEndpoint> target = [[CBLURLEndpoint alloc] initWithURL: [NSURL URLWithString: CBLConfig.shared.syncEndpoint]];
    CBLReplicatorConfiguration* config = [[CBLReplicatorConfiguration alloc] initWithTarget: target];
    config.continuous = continuous;
    
    CBLAuthenticator* auth = nil;
    NSString* username = CBLSession.sharedInstance.username;
    NSString* password = CBLSession.sharedInstance.password;
    if (username && password) {
        auth = [[CBLBasicAuthenticator alloc] initWithUsername: username password: password];
    }
    config.authenticator = auth;
    
    config.maxAttempts = CBLConfig.shared.maxAttempts;
    config.maxAttemptWaitTime = CBLConfig.shared.maxAttemptWaitTime;
    
    id<CBLConflictResolver> conflictResolver = nil;
    if ([CBLConfig shared].ccrEnabled) {
        conflictResolver = [[TestConflictResolver alloc] initWithResolver: ^CBLDocument* (CBLConflict* con) {
            switch ([CBLConfig shared].ccrType) {
                case CCRTypeLocal:
                    return con.localDocument;
                case CCRTypeRemote:
                    return con.remoteDocument;
                case CCRTypeDelete:
                    return nil;
            }
            return con.remoteDocument;
        }];
    }
    
    CBLCollectionConfiguration* collConfig = [[CBLCollectionConfiguration alloc] init];
    collConfig.conflictResolver = conflictResolver;
    [config addCollections: @[self.taskLists, self.tasks, self.users] config: collConfig];
    
    return config;
}

// MARK: Lists

- (BOOL) createTaskListWithName: (NSString*)name error: (NSError**)error {
    NSString* docID = $S(@"%@.%@", self.currentUser, [NSUUID UUID].UUIDString);
    CBLMutableDocument* doc = [[CBLMutableDocument alloc] initWithID: docID];
    [doc setValue: name forKey: @"name"];
    [doc setValue: self.currentUser forKey: @"owner"];
    return [self.taskLists saveDocument: doc error: error];
}

- (BOOL) updateTaskListWithID: (NSString*)listID name: (NSString*)name error: (NSError**)error {
    CBLMutableDocument* doc = [self getMutableDocWithID: listID collection: self.taskLists error: error];
    if (!doc) return false;
    
    [doc setValue: name forKey: @"name"];
    [doc setValue: self.currentUser forKey: @"owner"];
    return [self.taskLists saveDocument: doc error: error];
}

- (BOOL) deleteTaskListWithID: (NSString*)listID error: (NSError**)error {
    return [self deleteDocWithID: listID collection: self.taskLists error: error];
}

- (nullable CBLDocument*) getTaskListByID: (NSString*)listID error: (NSError**)error {
    return [self.taskLists documentWithID: listID error: error];
}

- (nullable CBLQueryResultSet*) getTaskListsByName: (NSString*)name error: (NSError**)error {
    NSString* query = $S(@"SELECT meta().id, name FROM %@ WHERE name LIKE '%%%@%%' ORDER BY name", self.taskLists.name, name);
    return [[self.openedDB createQuery: query error: error] execute: error];
}

- (nullable CBLQuery*) getTaskListsQuery: (NSError**)error {
    NSString* query = $S(@"SELECT meta().id, name FROM %@ ORDER BY name", self.taskLists.name);
    return [self.openedDB createQuery: query error: error];
}

- (nullable CBLQuery*) getIncompletedTasksCountsQuery: (NSError**)error {
    NSString* query = $S(@"SELECT taskList.id, count(1) FROM %@ WHERE complete == false GROUP BY taskList.id", self.taskLists.name);
    return [self.openedDB createQuery: query error: error];
}

// MARK: Tasks

- (BOOL) createTaskForTaskList: (CBLDocument*)taskList task: (NSString*)task extra: (NSString*)extra error: (NSError**)error {
    CBLMutableDocument* doc = [[CBLMutableDocument alloc] init];
    NSString* owner = [taskList stringForKey: @"owner"];
    NSDictionary* taskListInfo = @{@"id": taskList.id, @"owner": owner};
    [doc setValue: taskListInfo forKey: @"taskList"];
    [doc setValue: task forKey: @"task"];
    [doc setBoolean: false forKey: @"complete"];
    [doc setValue: [NSDate date] forKey: @"createdAt"];
    if (extra) {
        [doc setString: extra forKey: @"extra"];
    }
    return [self.tasks saveDocument: doc error: error];
}

- (BOOL) updateTaskWithID: (NSString*)taskID task: (NSString*)task error: (NSError**)error {
    CBLMutableDocument* doc = [self getMutableDocWithID: taskID collection: self.tasks error: error];
    if (!doc) return false;
    
    [doc setValue: task forKey: @"task"];
    return [self.tasks saveDocument: doc error: error];
}

- (BOOL) updateTaskWithID: (NSString*)taskID complete: (BOOL)complete error: (NSError**)error {
    CBLMutableDocument* doc = [self getMutableDocWithID: taskID collection: self.tasks error: error];
    if (!doc) return false;
    
    [doc setBoolean: complete forKey: @"complete"];
    return [self.tasks saveDocument: doc error: error];
}

- (BOOL) updateTaskWithID: (NSString*)taskID image: (UIImage*)image error: (NSError**)error {
    CBLMutableDocument* doc = [self getMutableDocWithID: taskID collection: self.tasks error: error];
    if (!doc) return false;
    
    CBLBlob* blob = nil;
    if (image) {
        NSData* imageData = UIImageJPEGRepresentation(image, 0.5);
        if (!imageData) {
            return [self checkError: [self CBLError: CBLErrorInvalidParameter] outError: error];
        }
        blob = [[CBLBlob alloc] initWithContentType:@"image/jpg" data: imageData];
    }
    
    [doc setValue: blob forKey: @"image"];
    return [self.tasks saveDocument: doc error: error];
}

- (BOOL) deleteTaskWithID: (NSString*)taskID error: (NSError**)error {
    return [self deleteDocWithID: taskID collection: self.tasks error: error];
}

- (nullable CBLDocument*) getTaskByID: (NSString*)taskID error: (NSError**)error {
    return [self.tasks documentWithID: taskID error: error];
}

- (nullable CBLQuery*) getTasksQueryForTaskListID: (NSString*)listID error: (NSError**)error {
    NSString* query = $S(@"SELECT meta().id, task, complete, image FROM %@ WHERE taskList.id == '%@' ORDER BY createdAt, task", self.tasks.name, listID);
    return [self.openedDB createQuery: query error: error];
}

- (nullable CBLQueryResultSet*) getTasksForTaskListID: (NSString*)listID error: (NSError**)error {
    return [[self getTasksQueryForTaskListID: listID error: error] execute: error];
}

- (nullable CBLQueryResultSet*) getTasksForTaskListID: (NSString*)listID task: (NSString*)task error: (NSError**)error {
    NSString* query = $S(@"SELECT meta().id, task, complete, image FROM %@ WHERE taskList.id == '%@' AND task LIKE '%%%@%%' ORDER BY createdAt, task", self.tasks.name, listID, task);
    return [[self.openedDB createQuery: query error: error] execute: error];
}

// MARK: Users

- (BOOL) addSharedUserForTaskList: (CBLDocument*)taskList username: (NSString*)username error: (NSError**)error {
    NSString* docID = $S(@"%@.%@", taskList.id, username);
    CBLMutableDocument* doc = [[CBLMutableDocument alloc] initWithID: docID];
    [doc setValue: username forKey: @"username"];
    
    NSDictionary* taskListInfo = @{@"id": taskList.id, @"owner": [taskList valueForKey: @"owner"]};
    [doc setValue: taskListInfo forKey: @"taskList"];
    
    return [self.users saveDocument: doc error: error];
}

- (BOOL) deletedSharedUserWithID: (NSString*)userID error: (NSError**)error {
    return [self deleteDocWithID: userID collection: self.users error: error];
}

- (nullable CBLDocument*) getSharedUserByID: (NSString*)userID error: (NSError**)error {
    return [self.users documentWithID: userID error: error];
}

- (nullable CBLQuery*) getSharedUsersQueryForTaskList: (CBLDocument*)taskList error: (NSError**)error {
    NSString* query = $S(@"SELECT meta().id, username FROM %@ WHERE taskList.id == '%@' ORDER BY username", self.users.name, taskList.id);
    return [self.openedDB createQuery: query error: error];
}

- (nullable CBLQueryResultSet*) getSharedUsersForTaskListID: (NSString*)listID error: (NSError**)error {
    NSString* query = $S(@"SELECT meta().id, username FROM %@ WHERE taskList.id == '%@' ORDER BY username", self.users.name, listID);
    return [[self.openedDB createQuery: query error: error] execute: error];
}

- (nullable CBLQueryResultSet*) getSharedUsersForTaskList: (CBLDocument*)taskList username: (NSString*)username error: (NSError**)error; {
    NSString* query = $S(@"SELECT meta().id, username FROM %@ WHERE taskList.id == '%@' AND username LIKE '%%%@%%' ORDER BY username", self.users.name, taskList.id, username);
    return [[self.openedDB createQuery: query error: error] execute: error];
}

// MARK: Utils

- (CBLMutableDocument*) getMutableDocWithID: (NSString*)docID collection: (CBLCollection*)collection error: (NSError**)error {
    NSError* err = nil;
    CBLMutableDocument* doc = [[collection documentWithID: docID error: &err] toMutable];
    if (!doc) {
        [self checkError: err ?: [self CBLError: CBLErrorNotFound] outError: error];
    }
    return doc;
}

- (BOOL) deleteDocWithID: (NSString*)docID collection: (CBLCollection*)collection error: (NSError**)error {
    NSError* err = nil;
    CBLDocument* doc = [collection documentWithID: docID error: &err];
    if (doc) {
        return [collection deleteDocument: doc error: error];
    }
    return [self checkError: err outError: error];
}

- (NSError*) CBLError: (NSInteger)code {
    return [NSError errorWithDomain: CBLErrorDomain code: CBLErrorNotFound userInfo: nil];
}

- (BOOL) checkError: (NSError*)error outError: (NSError**)outError {
    if (outError) {
        *outError = error;
    }
    return error == nil;
}

- (NSString *)ativityLevel:(CBLReplicatorActivityLevel)level {
    switch (level) {
        case kCBLReplicatorStopped:
            return @"STOPPED";
        case kCBLReplicatorOffline:
            return @"OFFLINE";
        case kCBLReplicatorConnecting:
            return @"CONNECTING";
        case kCBLReplicatorIdle:
            return @"IDLE";
        case kCBLReplicatorBusy:
            return @"BUSY";
        default:
            return @"UNKNOWN";
    }
}

@end

#pragma mark - CCR Helper class

@implementation TestConflictResolver {
    CBLDocument* (^_resolver)(CBLConflict*);
}

- (instancetype) initWithResolver: (CBLDocument* (^)(CBLConflict*))resolver {
    self = [super init];
    if (self) {
        _resolver = resolver;
    }
    return self;
}

- (CBLDocument *) resolve:(CBLConflict *)conflict {
    return _resolver(conflict);
}

@end
