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
#import "CBLUi.h"
#import "CBLTasksViewController.h"

@interface CBLListsViewController () <UISearchResultsUpdating> {
    UISearchController *_searchController;
    
    CBLDatabase *_database;
    NSString *_username;
    
    CBLPredicateQuery *_listQuery;
    CBLPredicateQuery *_searchQuery;
    NSArray* _listRows;
    
    CBLPredicateQuery *_incompTasksCountsQuery;
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
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    // Get username:
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _username = app.username;
    
    // Get database:
    _database = app.database;
    
    // Load data:
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (shouldUpdateIncompTasksCount)
        [self updateIncompleteTasksCounts];
}

#pragma mark - Database

- (void)reload {
    if (!_listQuery) {
        _listQuery = [_database createQueryWhere:@"type == 'task-list'"];
        _listQuery.orderBy = @[@"name"];
    }
    
    NSError *error;
    NSEnumerator *rows = [_listQuery run: &error];
    if (!rows)
        NSLog(@"Error querying task list: %@", error);
    
    _listRows = [rows allObjects];
    
    [self updateIncompleteTasksCounts];
    
    [self.tableView reloadData];
}

- (void)updateIncompleteTasksCounts {
    shouldUpdateIncompTasksCount = NO;
    
    if (!_incompTasksCountsQuery) {
        _incompTasksCountsQuery = [_database createQueryWhere:@"type == 'task' AND complete == false"];
        _incompTasksCountsQuery.groupBy = @[@"taskList.id"];
        _incompTasksCountsQuery.returning = @[@"taskList.id", @"count(1)"];
    }
    
    NSError *error;
    NSEnumerator *rows = [_incompTasksCountsQuery run: &error];
    if (!rows)
        NSLog(@"Error querying incomplete tasks counts: %@", error);
    
    if (!_incompTasksCounts)
        _incompTasksCounts = [NSMutableDictionary dictionary];
    
    [_incompTasksCounts removeAllObjects];
    for (CBLQueryRow *row in rows) {
        _incompTasksCounts[row[0]] = row[1];
    }
    [self.tableView reloadData];
}

- (void)createTaskList:(NSString*)name {
    NSString *docId = [NSString stringWithFormat:@"%@.%@", _username, [NSUUID UUID].UUIDString];
    CBLDocument *doc = [[CBLDocument alloc] initWithID: docId];
    [doc setObject:@"task-list" forKey:@"type"];
    [doc setObject:name forKey:@"name"];
    [doc setObject:_username forKey:@"owner"];
    
    NSError *error;
    if ([_database saveDocument:doc error:&error])
        [self reload];
    else
        [CBLUi showErrorOn:self message:@"Couldn't save task list" error:error];
}

- (void)updateTaskList:(CBLDocument *)list withName:(NSString *)name {
    [list setObject:name forKey:@"name"];
    NSError *error;
    if ([_database saveDocument:list error:&error])
        [self reload];
    else
        [CBLUi showErrorOn:self message:@"Couldn't update task list" error:error];
}

- (void)deleteTaskList:(CBLDocument *)list {
    NSError *error;
    if ([_database deleteDocument:list error:&error])
        [self reload];
    else
        [CBLUi showErrorOn:self message:@"Couldn't delete task list" error:error];
}

- (void)searchTaskList: (NSString*)name {
    if (!_searchQuery) {
        _searchQuery = [_database createQueryWhere:@"type == 'task-list' AND name contains[c] $NAME"];
        _searchQuery.orderBy = @[@"name"];
    }
    
    _searchQuery.parameters = @{@"NAME": name};
    
    NSError *error;
    NSEnumerator *rows = [_searchQuery run: &error];
    if (!rows)
        NSLog(@"Error searching task list: %@", error);
    
    _listRows = [rows allObjects];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_listRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskListCell"
                                                            forIndexPath:indexPath];
    CBLQueryRow *row = _listRows[indexPath.row];
    cell.textLabel.text = [row.document stringForKey:@"name"];
    
    NSInteger count = [_incompTasksCounts[row.documentID] integerValue];
    cell.detailTextLabel.text = count > 0 ? [NSString stringWithFormat:@"%ld", (long)count] : @"";
    
    return cell;
}

-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                 editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Delete action:
    UITableViewRowAction *delete =
        [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                           title:@"Delete"
                                         handler:
     ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
         // Dismiss row actions:
         [tableView setEditing:NO animated:YES];
         
         // Delete list document:
         CBLDocument *doc = ((CBLQueryRow*)_listRows[indexPath.row]).document;
         [self deleteTaskList:doc];
    }];
    delete.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    
    // Update action:
    UITableViewRowAction *update = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                      title:@"Edit"
                                                                    handler:
     ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
         // Dismiss row actions:
         [tableView setEditing:NO animated:YES];
         
         // Get the document:
         CBLDocument *doc = ((CBLQueryRow *)_listRows[indexPath.row]).document;
         
         // Display update list dialog:
         [CBLUi showTextInputOn:self title:@"Edit List" message:nil textField:^(UITextField *text) {
             text.placeholder = @"List name";
             text.text = [doc stringForKey:@"name"];
         } onOk:^(NSString *name) {
             // Update task list with a new name:
             [self updateTaskList:doc withName:name];
         }];
    }];
    update.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    
    return @[delete, update];
}

#pragma mark - UISearchController

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *name = searchController.searchBar.text ?: @"";
    if ([name length] > 0)
        [self searchTaskList:name];
    else
        [self reload];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    CBLQueryRow *row = (CBLQueryRow *)_listRows[[self.tableView indexPathForSelectedRow].row];
    CBLTasksViewController *controller = (CBLTasksViewController*)segue.destinationViewController;
    controller.taskList = row.document;
    shouldUpdateIncompTasksCount = YES;
}

@end
