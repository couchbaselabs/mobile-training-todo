//
// CBLTasksViewController.m
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

#import "CBLTasksViewController.h"
#import "CBLTaskImageViewController.h"
#import "CBLTaskTableViewCell.h"

#import "AppDelegate.h"
#import "CBLDB.h"
#import "CBLUi.h"
#import "CBLImage.h"
#import "CBLSession.h"
#import "CBLDocLogger.h"

@interface CBLTasksViewController () <UISearchResultsUpdating,
                                      UISearchBarDelegate,
                                      UIImagePickerControllerDelegate,
                                      UINavigationControllerDelegate>
{
    UISearchController* _searchController;
    
    NSString* _username;
    
    CBLQuery* _taskQuery;
    NSArray <CBLQueryResult*>* _taskRows;
    
    CBLQuery* _searchQuery;
    BOOL _inSearch;
    NSArray <CBLQueryResult*>* _searchRows;
    
    NSString* _selectedTaskIDForImage;
    CBLBlob* _selectedImage;
}

@end

@implementation CBLTasksViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup Search Controller:
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    _username = CBLSession.sharedInstance.username;
    
    // Load data:
    [self reload];
    
    // Display or hide users:
    [self displayOrHideUsers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Setup navigation bar:
    self.tabBarController.title = [self.taskList stringForKey:@"name"];
    self.tabBarController.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                      target:self action:@selector(addAction:)];
}

#pragma mark - Database

- (void)reload {
    assert(_taskList);
    
    if (!_taskQuery) {
        NSError* error;
        _taskQuery = [CBLDB.shared getTasksQueryForTaskListID: _taskList.id error: &error];
        if (!_taskQuery) {
            NSLog(@"Error creating tasks query: %@", error);
            return;
        }
        
        __weak typeof (self) wSelf = self;
        [_taskQuery addChangeListener: ^(CBLQueryChange *change) {
            if (!change.results) {
                NSLog(@"Error querying tasks: %@", change.error);
            }
            _taskRows = [change.results allObjects];
            [wSelf.tableView reloadData];
        }];
    }
}

- (void) createTask: (NSString*)task {
    NSError* error;
    if (![CBLDB.shared createTaskForTaskList: _taskList task: task extra: nil error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't save task" error: error];
    }
}

- (void) updateTask: (NSString*)taskID withTitle: (NSString*)title {
    NSError* error;
    if (![CBLDB.shared updateTaskWithID: taskID task: title error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't update task" error: error];
    }
}

- (void) updateTask: (NSString*)taskID withComplete: (BOOL)complete {
    NSError* error;
    if (![CBLDB.shared updateTaskWithID: taskID complete: complete error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't update complete status" error: error];
    }
}

- (void) updateTask: (NSString*)taskID withImage: (UIImage*)image {
    NSError* error;
    if (![CBLDB.shared updateTaskWithID: taskID image: image error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't update task image" error: error];
    }
}

- (void) deleteTask: (NSString*)taskID {
    NSError* error;
    if (![CBLDB.shared deleteTaskWithID: taskID error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't delete task" error: error];
    }
}

- (void) searchTask: (NSString*)name {
    NSError* error;
    CBLQueryResultSet* rows = [CBLDB.shared getTasksForTaskListID: _taskList.id error: &error];
    if (!rows) {
        NSLog(@"Error searching tasks: %@", error);
    }
    _searchRows = [rows allObjects];
    [self.tableView reloadData];
}

#pragma mark - Users

- (void) displayOrHideUsers {
    BOOL display = [_username isEqualToString: [_taskList stringForKey: @"owner"]];
    [CBLUi displayOrHideTabbar: self display: display];
}

#pragma mark - Actions

- (IBAction) addAction:(id)sender {
    [CBLUi showTextInputOn: self title: @"New Task" message: nil textField: ^(UITextField* text) {
        text.placeholder = @"Task";
        text.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } onOk: ^(NSString* name) {
        [self createTask: name];
    }];
}

#pragma mark - Table view data source

- (NSArray<CBLQueryResult*>*) data {
    return _inSearch ? _searchRows : _taskRows;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView*)tableView {
    return 1;
}

- (NSInteger) tableView: (UITableView*)tableView numberOfRowsInSection: (NSInteger)section {
    return self.data.count;
}

- (UITableViewCell*) tableView: (UITableView*)tableView cellForRowAtIndexPath: (NSIndexPath*)indexPath {
    CBLTaskTableViewCell* cell =
        (CBLTaskTableViewCell*)[tableView dequeueReusableCellWithIdentifier: @"TaskCell" forIndexPath: indexPath];
    
    CBLQueryResult* result = self.data[indexPath.row];
    NSString* taskID = [result stringForKey: @"id"];
    NSString* task = [result stringForKey: @"task"];
    BOOL complete = [result booleanForKey: @"complete"];
    CBLBlob* imageBlob = [result blobForKey: @"image"];
    
    cell.taskLabel.text = task;
    cell.accessoryType = complete ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    if (imageBlob) {
        UIImage* image = [UIImage imageWithData: imageBlob.content scale: [UIScreen mainScreen].scale];
        NSString* digest = imageBlob.digest;
        UIImage* thumbnail = [CBLImage square: image
                                     withSize: 44.0
                                withCacheName: digest
                                   onComplete: ^(UIImage* result) {
            [self updateImage: result withDigest: digest atIndexPath: indexPath];
        }];
        cell.taskImage = thumbnail;
        cell.taskImageAction = ^() {
            _selectedTaskIDForImage = taskID;
            _selectedImage = imageBlob;
            [self performSegueWithIdentifier: @"showTaskImage" sender: self];
        };
    } else {
        cell.taskImage = nil;
        cell.taskImageAction = ^() {
            _selectedTaskIDForImage = taskID;
            [CBLUi showImageActionSheet: self imagePickerDelegate: self onDelete: nil];
        };
    }
    return cell;
}

- (void) updateImage: (UIImage*)image withDigest: (NSString*)digest atIndexPath: (NSIndexPath*)indexPath {
    if (self.data.count <= indexPath.row) {
        return;
    }
    
    CBLQueryResult* row = self.data[indexPath.row];
    CBLBlob *imageBlob = [row blobForKey: @"image"];
    if ([imageBlob.digest isEqualToString: digest]) {
        CBLTaskTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.taskImage = image;
    }
}

- (void) tableView: (UITableView*)tableView didSelectRowAtIndexPath: (NSIndexPath*)indexPath {
    CBLQueryResult* row = self.data[indexPath.row];
    NSString* taskID = [row stringForKey: @"id"];
    BOOL complete = ![row booleanForKey: @"complete"];
    [self updateTask: taskID withComplete: complete];
    
    // Optimistically update the UI:
    CBLTaskTableViewCell* cell = (CBLTaskTableViewCell*)[self.tableView cellForRowAtIndexPath: indexPath];
    cell.accessoryType = complete ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (NSArray<UITableViewRowAction *> *) tableView: (UITableView*)tableView
                   editActionsForRowAtIndexPath: (NSIndexPath*)indexPath
{
    CBLQueryResult* row = self.data[indexPath.row];
    NSString* taskID = [row stringForKey: @"id"];
    NSString* task = [row stringForKey: @"task"];
    
    UITableViewRowAction* delete =
        [UITableViewRowAction rowActionWithStyle: UITableViewRowActionStyleNormal
                                           title: @"Delete"
                                         handler: ^(UITableViewRowAction* action, NSIndexPath* indexPath)
    {
        // Dismiss row actions:
        [tableView setEditing:NO animated:YES];
        // Delete task document:
        [self deleteTask: taskID];
    }];
    delete.backgroundColor = [UIColor colorWithRed: 1.0 green: 0.23 blue: 0.19 alpha: 1.0];
    
    UITableViewRowAction* update =
        [UITableViewRowAction rowActionWithStyle: UITableViewRowActionStyleNormal
                                           title: @"Edit"
                                         handler: ^(UITableViewRowAction* action, NSIndexPath* indexPath)
    {
        // Dismiss row actions:
        [tableView setEditing: NO animated: YES];
        
        // Display update list dialog:
        [CBLUi showTextInputOn: self title: @"Edit Task" message: nil textField: ^(UITextField* text) {
            text.placeholder = @"Task";
            text.text = task;
            text.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        } onOk: ^(NSString* name) {
            [self updateTask: task withTitle: task];
        }];
    }];
    update.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.48 blue: 1.0 alpha: 1.0];
    
    // Log action:
    UITableViewRowAction* log = [UITableViewRowAction rowActionWithStyle: UITableViewRowActionStyleNormal
                                                                   title: @"Log"
                                                                 handler:
     ^(UITableViewRowAction* action, NSIndexPath* indexPath) {
        // Dismiss row actions:
        [tableView setEditing:NO animated:YES];
        // Log:
        [CBLDocLogger logTask: taskID];
    }];
    
    return @[delete, update, log];
}

#pragma mark - UISearchController

- (void) updateSearchResultsForSearchController: (UISearchController*)searchController {
    NSString *text = searchController.searchBar.text ?: @"";
    if ([text length] > 0) {
        _inSearch = YES;
        [self searchTask: text];
    } else {
        [self searchBarCancelButtonClicked: searchController.searchBar];
    }
}

- (void) searchBarCancelButtonClicked: (UISearchBar*)searchBar {
    _inSearch = NO;
    _searchRows = nil;
    [self.tableView reloadData];
}

#pragma mark - UIImagePickerControllerDelegate

-(void) imagePickerController: (UIImagePickerController*)picker didFinishPickingMediaWithInfo: (NSDictionary<NSString*,id>*)info {
    if (_selectedTaskIDForImage) {
        [self updateTask: _selectedTaskIDForImage withImage: info[@"UIImagePickerControllerOriginalImage"]];
        _selectedTaskIDForImage = nil;
    }
    [picker.presentingViewController dismissViewControllerAnimated: YES completion: nil];
}

#pragma mark - Navigation

- (void) prepareForSegue: (UIStoryboardSegue*)segue sender: (id)sender {
    if ([segue.identifier isEqualToString:@"showTaskImage"]) {
        UINavigationController* navController = segue.destinationViewController;
        CBLTaskImageViewController* controller = (CBLTaskImageViewController*)navController.topViewController;
        controller.taskID = _selectedTaskIDForImage;
        controller.imageBlob = _selectedImage;
        _selectedTaskIDForImage = nil;
        _selectedImage = nil;
    }
}

@end
