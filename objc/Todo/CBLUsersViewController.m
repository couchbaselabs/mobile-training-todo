//
// CBLUsersViewController.m
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

#import "CBLUsersViewController.h"
#import "CBLDB.h"
#import "CBLSession.h"
#import "CBLUi.h"

@interface CBLUsersViewController () <UISearchResultsUpdating, UISearchBarDelegate>

@end

@implementation CBLUsersViewController {
    UISearchController* _searchController;
    NSString* _username;
    CBLDatabase* _database;
    
    CBLQuery* _userQuery;
    NSArray<CBLQueryResult*>* _userRows;
    
    CBLQuery* _searchQuery;
    BOOL _inSearch;
    NSArray<CBLQueryResult*>* _searchRows;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Setup SearchController:
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    _username = CBLSession.sharedInstance.username;
    
    // Load data:
    [self reload];
}

- (void) viewWillAppear: (BOOL)animated {
    [super viewWillAppear: animated];
    
    // Setup navigation bar:
    self.tabBarController.title = [_taskList stringForKey:@"name"];
    self.tabBarController.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                  target: self action: @selector(addAction:)];
}

#pragma mark - Database

- (void) reload {
    assert(_taskList);
    
    if (!_userQuery) {
        NSError* error;
        _userQuery = [CBLDB.shared getSharedUsersQueryForTaskList: _taskList error: &error];
        if (!_userQuery) {
            NSLog(@"Error creating users query: %@", error);
            return;
        }
        
        __weak typeof(self) wSelf = self;
        [_userQuery addChangeListener: ^(CBLQueryChange* change) {
            if (!change.results)
                NSLog(@"Error querying users: %@", change.error);
            _userRows = [change.results allObjects];
            [wSelf.tableView reloadData];
        }];
    }
}

- (void) addUser: (NSString*)username {
    NSError* error;
    if (![CBLDB.shared addSharedUserForTaskList: _taskList username: username error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't save user" error: error];
    }
}

- (void) deleteUser: (NSString*)userID {
    NSError *error;
    if (![CBLDB.shared deletedSharedUserWithID: userID error: &error]) {
        [CBLUi showErrorOn: self message: @"Couldn't delete user" error: error];
    }
}

- (void) searchUser: (NSString*)username {
    NSError* error;
    CBLQueryResultSet* rows = [CBLDB.shared getSharedUsersForTaskList: _taskList username: username error: &error];
    if (!rows) {
        NSLog(@"Error searching users: %@", error);
    }
    _searchRows = [rows allObjects];
    [self.tableView reloadData];
}

#pragma mark - Action

- (IBAction) addAction: (id)sender {
    [CBLUi showTextInputOn: self title: @"Add User" message: nil textField: ^(UITextField *text) {
        text.placeholder = @"Username";
        text.autocapitalizationType = UITextAutocapitalizationTypeNone;
    } onOk: ^(NSString* name) {
        [self addUser: name];
    }];
}

#pragma mark - Table view data source

- (NSArray<CBLQueryResult*>*) data {
    return _inSearch ? _searchRows : _userRows;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView*)tableView {
    return 1;
}

- (NSInteger) tableView: (UITableView*)tableView numberOfRowsInSection: (NSInteger)section {
    return [self.data count];
}

- (UITableViewCell*) tableView: (UITableView*)tableView cellForRowAtIndexPath: (NSIndexPath*)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"UserCell" forIndexPath: indexPath];
    cell.textLabel.text = [self.data[indexPath.row] stringAtIndex: 1];
    return cell;
}

- (NSArray<UITableViewRowAction*>*)tableView: (UITableView*)tableView editActionsForRowAtIndexPath: (NSIndexPath*)indexPath {
    NSString* userID = [self.data[indexPath.row] stringAtIndex:0];
    
    UITableViewRowAction* delete =
    [UITableViewRowAction rowActionWithStyle: UITableViewRowActionStyleNormal
                                       title: @"Delete"
                                     handler: ^(UITableViewRowAction* action, NSIndexPath* indexPath) {
        // Dismiss row actions:
        [tableView setEditing: NO animated: YES];
        // Delete task document:
        [self deleteUser: userID];
    }];
    delete.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    return @[delete];
}

#pragma mark - UISearchController

- (void) updateSearchResultsForSearchController: (UISearchController*)searchController {
    NSString* text = searchController.searchBar.text ?: @"";
    if ([text length] > 0) {
        _inSearch = YES;
        [self searchUser: text];
    } else {
        [self searchBarCancelButtonClicked: searchController.searchBar];
    }
}

- (void) searchBarCancelButtonClicked: (UISearchBar*)searchBar {
    _inSearch = NO;
    _searchRows = nil;
    [self.tableView reloadData];
}

@end
