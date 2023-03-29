//
// CBLListsViewController.m
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

#import "CBLListsViewController.h"
#import "CBLTasksViewController.h"
#import "CBLUsersViewController.h"

#import "AppDelegate.h"
#import "CBLDB.h"
#import "CBLSession.h"
#import "CBLUi.h"
#import "CBLDocLogger.h"
#import "CBLConfig.h"

@interface CBLListsViewController () <UISearchResultsUpdating, UISearchBarDelegate> {
    UISearchController *_searchController;
    
    NSString* _username;
    
    CBLQuery* _listQuery;
    NSArray<CBLQueryResult*>* _listRows;
    
    CBLQuery* _searchQuery;
    BOOL _inSearch;
    NSArray<CBLQueryResult*>* _searchRows;
    
    CBLQuery* _incompTasksCountsQuery;
    
    NSMutableDictionary* _incompTasksCounts;
}

@end

@implementation CBLListsViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup SearchController:
    _searchController = [[UISearchController alloc] initWithSearchResultsController: nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.searchBar.delegate = self;
    
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    _username = [CBLSession sharedInstance].username;
    
    // Load data:
    [self reload];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self.navigationItem.leftBarButtonItem setEnabled: true];
}

- (void) updateReplicatorStatus: (CBLReplicatorActivityLevel)level {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIColor* color;
        switch (level) {
            case kCBLReplicatorConnecting:
            case kCBLReplicatorBusy:
                color = UIColor.yellowColor;
                break;
            case kCBLReplicatorIdle:
                color = UIColor.greenColor;
                break;
            case kCBLReplicatorOffline:
                color = UIColor.orangeColor;
                break;
            case kCBLReplicatorStopped:
                color = UIColor.redColor;
                break;
        }
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: color};
    });
}

#pragma mark - Database

- (void) reload {
    if (!_listQuery) {
        // Task List:
        NSError* error;
        _listQuery = [CBLDB.shared getTaskListsQuery: &error];
        if (!_listQuery) {
            NSLog(@"Error creating the task lists query: %@", error);
            return;
        }
        
        __weak typeof(self) wSelf = self;
        [_listQuery addChangeListener:^(CBLQueryChange *change) {
            if (!change.results)
                NSLog(@"Error querying task list: %@", change.error);
            _listRows = [change.results allObjects];
            [wSelf.tableView reloadData];
        }];
        
        // Incomplete tasks count:
        _incompTasksCountsQuery = [CBLDB.shared getIncompletedTasksCountsQuery: &error];
        if (!_incompTasksCountsQuery) {
            NSLog(@"Error creating the incomplete task counts query: %@", error);
            return;
        }
        
        [_incompTasksCountsQuery addChangeListener:^(CBLQueryChange *change) {
            if (change.results)
                [wSelf updateIncompleteTasksCounts: change.results];
            else
                NSLog(@"Error querying incomplete task counts: %@", change.error);
        }];
    }
}

- (void) updateIncompleteTasksCounts: (CBLQueryResultSet*)rows {
    if (!_incompTasksCounts)
        _incompTasksCounts = [NSMutableDictionary dictionary];
    [_incompTasksCounts removeAllObjects];
    
    for (CBLQueryResult* row in rows) {
        _incompTasksCounts[[row stringAtIndex: 0]] = [row valueAtIndex: 1];
    }
    [self.tableView reloadData];
}

- (void) createTaskList: (NSString*)name {
    [CBLDB.shared createTaskListWithName: name completion:^(bool success, NSError* error) {
        if (!success) {
            NSString* message = [NSString stringWithFormat: @"Couldn't save task list : %@", name];
            [CBLUi showErrorOn: self message: message error: error];
        }
    }];
}

- (void) updateTaskList: (NSString*)listID name: (NSString *)name {
    NSError* error;
    if (![CBLDB.shared updateTaskWithID: listID task: name error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't update task list" error: error];
    }
}

- (void) deleteTaskList: (NSString*)listID {
    NSError* error;
    if (![CBLDB.shared deleteTaskWithID: listID error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't delete task list" error: error];
    }
}

- (void) searchTaskList: (NSString*)name {
    NSError* error;
    CBLQueryResultSet* rows = [CBLDB.shared getTaskListsByName: name error: &error];
    if (!rows) {
        NSLog(@"Error searching task list: %@", error);
    }
    _searchRows = [rows allObjects];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction) addAction: (id)sender {
    [CBLUi showTextInputOn: self title: @"New Task List" message: nil textField: ^(UITextField *text) {
         text.placeholder = @"List name";
         text.autocapitalizationType = UITextAutocapitalizationTypeWords;
     } onOk: ^(NSString* _Nonnull name) {
         [self createTaskList: name];
     }];
}

- (IBAction) logoutAction: (id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: nil
                                                                   message: nil
                                                            preferredStyle: UIAlertControllerStyleActionSheet];
    
    [alert addAction: [UIAlertAction actionWithTitle: @"Close Database"
                                               style: UIAlertActionStyleDefault
                                             handler: ^(UIAlertAction* action) {
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app logout: CBLLogoutModeCloseDatabase];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete Database"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [app logout: CBLLogoutModeDeleteDatabase];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) { }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSArray<CBLQueryResult*>*) data {
    return _inSearch ? _searchRows : _listRows;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView*)tableView {
    return 1;
}

- (NSInteger) tableView: (UITableView*)tableView numberOfRowsInSection: (NSInteger)section {
    return [self.data count];
}

- (UITableViewCell*) tableView: (UITableView*)tableView
         cellForRowAtIndexPath: (NSIndexPath*)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"TaskListCell"
                                                            forIndexPath: indexPath];
    CBLQueryResult* row = self.data[indexPath.row];
    NSString* docID = [row stringAtIndex: 0];
    NSString* name = [row stringAtIndex: 1];
    
    cell.textLabel.text = name;
    
    NSInteger count = [_incompTasksCounts[docID] integerValue];
    cell.detailTextLabel.text = count > 0 ? [NSString stringWithFormat: @"%ld", (long)count] : @"";
    return cell;
}

- (NSArray<UITableViewRowAction *>*) tableView: (UITableView*)tableView
                  editActionsForRowAtIndexPath: (NSIndexPath*)indexPath
{
    CBLQueryResult* row = self.data[indexPath.row];
    NSString* listID = [row stringAtIndex: 0];
    NSString* name = [row stringAtIndex: 1];
    
    // Delete action:
    UITableViewRowAction* delete =
        [UITableViewRowAction rowActionWithStyle: UITableViewRowActionStyleNormal
                                           title: @"Delete"
                                         handler:
     ^(UITableViewRowAction* action, NSIndexPath* indexPath) {
         // Dismiss row actions:
         [tableView setEditing: NO animated: YES];
         // Delete list document:
         [self deleteTaskList: listID];
    }];
    delete.backgroundColor = [UIColor colorWithRed: 1.0 green: 0.23 blue: 0.19 alpha: 1.0];
    
    // Update action:
    UITableViewRowAction* update = [UITableViewRowAction rowActionWithStyle: UITableViewRowActionStyleNormal
                                                                      title: @"Edit"
                                                                    handler:
     ^(UITableViewRowAction* action, NSIndexPath* indexPath) {
         // Dismiss row actions:
         [tableView setEditing: NO animated: YES];
         
         // Display update list dialog:
         [CBLUi showTextInputOn: self title: @"Edit List" message: nil textField: ^(UITextField *text) {
             text.placeholder = @"List name";
             text.text = name;
         } onOk: ^(NSString* name) {
             // Update task list with a new name:
             [self updateTaskList: listID name: name];
         }];
    }];
    update.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.48 blue: 1.0 alpha: 1.0];
    
    // Log action:
    UITableViewRowAction* log = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                   title:@"Log"
                                                                 handler:
     ^(UITableViewRowAction* action, NSIndexPath* indexPath) {
        // Dismiss row actions:
        [tableView setEditing: NO animated: YES];
        // Log:
        [CBLDocLogger logTaskList: listID];
    }];
    return @[delete, update, log];
}

#pragma mark - UISearchController

- (void) updateSearchResultsForSearchController: (UISearchController*)searchController {
    NSString* name = searchController.searchBar.text ?: @"";
    if ([name length] > 0) {
        _inSearch = YES;
        [self searchTaskList: name];
    } else {
        [self searchBarCancelButtonClicked: searchController.searchBar];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _inSearch = NO;
    _searchRows = nil;
    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"showTaskList"]) {
        // TODO: Handle Error
        NSString *docID = [self.data[[self.tableView indexPathForSelectedRow].row] stringAtIndex:0];
        CBLDocument* taskList = [CBLDB.shared getTaskListByID: docID error: nil];
        
        UITabBarController *tabBarController = (UITabBarController*)segue.destinationViewController;
        CBLTasksViewController *tasksController = tabBarController.viewControllers[0];
        tasksController.taskList = taskList;
        
        CBLUsersViewController *usersController = tabBarController.viewControllers[1];
        usersController.taskList = taskList;
    }
}

@end
