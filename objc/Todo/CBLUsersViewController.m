//
//  CBLUsersViewController.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 6/15/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLUsersViewController.h"
#import "AppDelegate.h"
#import "CBLConstants.h"
#import "CBLSession.h"
#import "CBLUi.h"


@interface CBLUsersViewController () <UISearchResultsUpdating>

@end

@implementation CBLUsersViewController {
    UISearchController *_searchController;
    NSString *_username;
    CBLDatabase *_database;
    CBLLiveQuery *_userQuery;
    CBLQuery *_searchQuery;
    NSArray<CBLQueryResult*> *_userRows;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup SearchController:
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchController.dimsBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    // Get username and database:
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _database = app.database;
    _username = CBLSession.sharedInstance.username;
    
    // Load data:
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Setup navigation bar:
    self.tabBarController.title = [_taskList stringForKey:@"name"];
    self.tabBarController.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                  target:self action:@selector(addAction:)];
}

#pragma mark - Database

- (void)reload {
    if (!_userQuery) {
        CBLQueryExpression *exp1 = [TYPE equalTo:@"task-list.user"];
        CBLQueryExpression *exp2 = [TASK_LIST_ID equalTo: _taskList.id];
        
        _userQuery = [[CBLQuery select:@[S_ID, S_USERNAME]
                                  from:[CBLQueryDataSource database:_database]
                                 where:[exp1 andExpression:exp2]] toLive];
        __weak typeof(self) wSelf = self;
        [_userQuery addChangeListener:^(CBLLiveQueryChange *change) {
            if (!change.rows)
                NSLog(@"Error querying users: %@", change.error);
            _userRows = [change.rows allObjects];
            [wSelf.tableView reloadData];
        }];
    }
    [_userQuery start];
}

- (void)addUser:(NSString *)username {
    NSString *docId = [NSString stringWithFormat:@"%@.%@", _taskList.id, username];
    if ([_database contains:docId])
        return;
    
    CBLDocument *doc = [[CBLDocument alloc] initWithID:docId];
    [doc setObject:@"task-list.user" forKey:@"type"];
    [doc setObject:username forKey:@"username"];
    
    CBLDictionary *taskListInfo = [[CBLDictionary alloc] init];
    [taskListInfo setObject:_taskList.id forKey:@"id"];
    [taskListInfo setObject:[_taskList stringForKey:@"owner"] forKey:@"owner"];
    [doc setObject:taskListInfo forKey:@"taskList"];
    
    NSError *error;
    if (![_database saveDocument:doc error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't save user" error:error];
}

- (void)deleteUser:(CBLDocument *)user {
    NSError *error;
    if (![_database deleteDocument:user error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't delete user" error:error];
}

- (void)searchUser: (NSString*)username {
    CBLQueryExpression *exp1 = [TYPE equalTo:@"task-list.user"];
    CBLQueryExpression *exp2 = [TASK_LIST_ID equalTo: _taskList.id];
    CBLQueryExpression *exp3 = [USERNAME like: [NSString stringWithFormat:@"%@%%", username]];
    _searchQuery = [CBLQuery select:@[S_ID, S_USERNAME]
                               from:[CBLQueryDataSource database:_database]
                              where:[[exp1 andExpression:exp2] andExpression:exp3]];
    NSError *error;
    NSEnumerator *rows = [_searchQuery run: &error];
    if (!rows)
        NSLog(@"Error searching tasks: %@", error);
    
    _userRows = [rows allObjects];
    [self.tableView reloadData];
}

#pragma mark - Action

- (IBAction)addAction:(id)sender {
    [CBLUi showTextInputOn:self title:@"Add User" message:nil textField:^(UITextField *text) {
        text.placeholder = @"Username";
        text.autocapitalizationType = UITextAutocapitalizationTypeNone;
    } onOk:^(NSString *name) {
        [self addUser:name];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_userRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    cell.textLabel.text = [_userRows[indexPath.row] stringAtIndex:1];
    return cell;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* docID = [_userRows[indexPath.row] stringAtIndex:0];
    CBLDocument *doc = [_database documentWithID:docID];
    
    UITableViewRowAction *delete =
    [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                       title:@"Delete"
                                     handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        // Dismiss row actions:
        [tableView setEditing:NO animated:YES];
        // Delete task document:
        [self deleteUser:doc];
    }];
    delete.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    return @[delete];
}

#pragma mark - UISearchController

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text ?: @"";
    if ([text length] > 0) {
        [_userQuery stop];
        [self searchUser:text];
    } else
        [self reload];
}

@end
