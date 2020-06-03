//
//  CBLListsViewController.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLListsViewController.h"
#import <CouchbaseLite/CouchbaseLite.h>
#import "AppDelegate.h"
#import "CBLConstants.h"
#import "CBLSession.h"
#import "CBLTasksViewController.h"
#import "CBLUsersViewController.h"
#import "CBLUi.h"

@interface CBLListsViewController () <UISearchResultsUpdating, UISearchBarDelegate> {
    UISearchController *_searchController;
    
    CBLDatabase *_database;
    NSString *_username;
    
    CBLQuery *_listQuery;
    NSArray<CBLQueryResult*>* _listRows;
    
    CBLQuery *_searchQuery;
    BOOL _inSearch;
    NSArray<CBLQueryResult*>* _searchRows;
    
    CBLQuery *_incompTasksCountsQuery;
    
    NSMutableDictionary *_incompTasksCounts;
    BOOL shouldUpdateIncompTasksCount;
}

@end

@implementation CBLListsViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup SearchController:
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.searchBar.delegate = self;
    
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    // Get database and username:
    // Get username:
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;    
    _database = app.database;
    _username = [CBLSession sharedInstance].username;
    
    // Load data:
    [self reload];
}

#pragma mark - Database

- (void)reload {
    if (!_listQuery) {
        // TASK LIST:
        _listQuery = [CBLQueryBuilder select:@[S_ID, S_NAME]
                                        from:[CBLQueryDataSource database:_database]
                                       where:[TYPE equalTo:[CBLQueryExpression string:@"task-list"]]
                                     orderBy:@[[CBLQueryOrdering expression:NAME]]];
        
        // INCOMPLETE TASKS COUNT:
        _incompTasksCountsQuery = [CBLQueryBuilder select:@[S_TASK_LIST_ID, S_COUNT]
                                                     from:[CBLQueryDataSource database:_database]
                                                    where:[[TYPE equalTo:[CBLQueryExpression string:@"task"]]
                                                           andExpression:[COMPLETE equalTo:[CBLQueryExpression boolean:NO]]]
                                                  groupBy:@[TASK_LIST_ID]];
        
        __weak typeof(self) wSelf = self;
        [_listQuery addChangeListener:^(CBLQueryChange *change) {
            if (!change.results)
                NSLog(@"Error querying task list: %@", change.error);
            _listRows = [change.results allObjects];
            [wSelf.tableView reloadData];
        }];
        
        [_incompTasksCountsQuery addChangeListener:^(CBLQueryChange *change) {
            if (change.results)
                [wSelf updateIncompleteTasksCounts: change.results];
            else
                NSLog(@"Error querying incomplete task count: %@", change.error);
        }];
    }
}

- (void)updateIncompleteTasksCounts:(CBLQueryResultSet*)rows {
    if (!_incompTasksCounts)
        _incompTasksCounts = [NSMutableDictionary dictionary];
    [_incompTasksCounts removeAllObjects];
    
    for (CBLQueryResult *row in rows) {
        _incompTasksCounts[[row stringAtIndex:0]] = [row valueAtIndex:1];
    }
    [self.tableView reloadData];
}


- (void)createTaskList:(NSString *)name {
    NSString *docId = [NSString stringWithFormat:@"%@.%@", _username, [NSUUID UUID].UUIDString];
    CBLMutableDocument *doc = [[CBLMutableDocument alloc] initWithID: docId];
    [doc setValue:@"task-list" forKey:@"type"];
    [doc setValue:name forKey:@"name"];
    [doc setValue:_username forKey:@"owner"];
    
    NSError *error;
    if (![_database saveDocument:doc error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't save task list" error:error];
}

- (void)updateTaskList:(NSString *)listID withName:(NSString *)name {
    CBLMutableDocument* list = [[_database documentWithID: listID] toMutable];
    [list setValue:name forKey:@"name"];
    NSError *error;
    if (![_database saveDocument:list error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update task list" error:error];
}

- (void)deleteTaskList:(NSString *)listID {
    NSError *error;
    CBLDocument* list = [_database documentWithID: listID];
    if (![_database deleteDocument:list error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't delete task list" error:error];
}

- (void)searchTaskList: (NSString*)name {
    _searchQuery = [CBLQueryBuilder select:@[S_ID, S_NAME]
                                      from:[CBLQueryDataSource database:_database]
                                     where:[[TYPE equalTo:[CBLQueryExpression string:@"task-list"]] andExpression:
                                            [NAME like:[CBLQueryExpression string:[NSString stringWithFormat:@"%%%@%%", name]]]]
                                   orderBy:@[[CBLQueryOrdering expression: NAME]]];
    
    NSError *error;
    NSEnumerator *rows = [_searchQuery execute: &error];
    if (!rows)
        NSLog(@"Error searching task list: %@", error);
    
    _searchRows = [rows allObjects];
    
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)addAction:(id)sender {
    [CBLUi showTextInputOn:self title:@"New Task List" message:nil textField:^(UITextField *text) {
         text.placeholder = @"List name";
         text.autocapitalizationType = UITextAutocapitalizationTypeWords;
     } onOk:^(NSString * _Nonnull name) {
         [self createTaskList:name];
     }];
}

- (IBAction)logoutAction:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Close Database"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
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

- (NSArray<CBLQueryResult*>*)data {
    return _inSearch ? _searchRows : _listRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskListCell"
                                                            forIndexPath:indexPath];
    
    CBLQueryResult *row = self.data[indexPath.row];
    NSString *docID = [row stringAtIndex:0];
    NSString *name = [row stringAtIndex:1];
    
    cell.textLabel.text = name;
    
    NSInteger count = [_incompTasksCounts[docID] integerValue];
    cell.detailTextLabel.text = count > 0 ? [NSString stringWithFormat:@"%ld", (long)count] : @"";
    return cell;
}

-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                 editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *docID = [self.data[indexPath.row] stringAtIndex:0];
    
    // Delete action:
    UITableViewRowAction *delete =
        [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                           title:@"Delete"
                                         handler:
     ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
         // Dismiss row actions:
         [tableView setEditing:NO animated:YES];
         
         // Delete list document:
         [self deleteTaskList:docID];
    }];
    delete.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    
    // Update action:
    UITableViewRowAction *update = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                      title:@"Edit"
                                                                    handler:
     ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
         // Dismiss row actions:
         [tableView setEditing:NO animated:YES];
         
         // Display update list dialog:
         CBLDocument *doc = [_database documentWithID:docID];
         [CBLUi showTextInputOn:self title:@"Edit List" message:nil textField:^(UITextField *text) {
             text.placeholder = @"List name";
             text.text = [doc stringForKey:@"name"];
         } onOk:^(NSString *name) {
             // Update task list with a new name:
             [self updateTaskList:docID withName:name];
         }];
    }];
    update.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    
    return @[delete, update];
}

#pragma mark - UISearchController

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *name = searchController.searchBar.text ?: @"";
    if ([name length] > 0) {
        _inSearch = YES;
        [self searchTaskList:name];
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
    NSString *docID = [self.data[[self.tableView indexPathForSelectedRow].row] stringAtIndex:0];
    CBLDocument *taskList = [_database documentWithID:docID];
    
    UITabBarController *tabBarController = (UITabBarController*)segue.destinationViewController;
    CBLTasksViewController *tasksController = tabBarController.viewControllers[0];
    tasksController.taskList = taskList;
    
    CBLUsersViewController *usersController = tabBarController.viewControllers[1];
    usersController.taskList = taskList;
    
    shouldUpdateIncompTasksCount = YES;
}

@end
