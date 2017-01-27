//
//  CBLListsViewController.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLListsViewController.h"
#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>
#import "CBLUi.h"

@interface CBLListsViewController () {
    CBLDatabase *_database;
    NSString *_username;
    CBLQuery *_query;
    NSArray* _listRows;
}

@end

@implementation CBLListsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _database = app.database;
    _username = app.username;
    
    [self setupQuery];
}

- (void)viewWillAppear:(BOOL)animated {
    [self reload];
}

- (void)setupQuery {
    NSError *error;
    _query = [_database createQueryWhere:@"type == 'task-list'"
                                 orderBy:@[@"name"]
                               returning:nil
                                   error:&error];
    if (!_query)
        NSLog(@"Error creating a query: %@", error);
}

- (void)reload {
    NSError* error;
    NSEnumerator *e = [_query run: &error];
    if (!e) {
        NSLog(@"Error querying task list: %@", error);
    }
    _listRows = [e allObjects];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)addAction:(id)sender {
    [CBLUi showTextInputDialog:self
                     withTitle:@"New Task List"
                   withMessage:nil
           withTextFeildConfig:^(UITextField * _Nonnull textField) {
               textField.placeholder = @"List name";
               textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskListCell"
                                                            forIndexPath:indexPath];
    CBLQueryRow *row = _listRows[indexPath.row];
    cell.textLabel.text = row.document[@"name"];
    cell.detailTextLabel.text = nil;
    return cell;
}

-(NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
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
    
    UITableViewRowAction *update = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                      title:@"Edit"
                                                                    handler:
        ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            // Dismiss row actions:
            [tableView setEditing:NO animated:YES];
            
            // Get the document:
            CBLDocument *doc = ((CBLQueryRow *)_listRows[indexPath.row]).document;
            
            // Display update list dialog:
            [CBLUi showTextInputDialog:self
                             withTitle:@"Edit List"
                           withMessage:nil
                   withTextFeildConfig:^(UITextField * _Nonnull textField) {
                       textField.placeholder = @"List name";
                       textField.text = doc[@"name"];
                   } onOk:^(NSString * _Nonnull name) {
                       // Update task list with a new name:
                       [self updateTaskList:doc withName:name];
                   }];
    }];
    update.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    
    return @[delete, update];
}

- (void)createTaskList:(NSString*)name {
    NSString *docId = [NSString stringWithFormat:@"%@.%@", _username, [NSUUID UUID].UUIDString];
    CBLDocument *doc = [_database documentWithID:docId];
    doc[@"type"] = @"task-list";
    doc[@"name"] = name;
    doc[@"owner"] = _username;
    
    NSError *error;
    if (![doc save: &error])
        [CBLUi showMessageDialog:self withTitle:@"Error" withMessage:@"Couldn't save task list"];
    [self reload];
}

- (void)updateTaskList:(CBLDocument *)doc withName:(NSString *)name {
    doc[@"name"] = name;
    NSError *error;
    if (![doc save: &error])
        [CBLUi showMessageDialog:self withTitle:@"Error" withMessage:@"Couldn't update task list"];
    [self reload];
}

- (void)deleteTaskList:(CBLDocument *)list {
    NSError *error;
    if (![list deleteDocument: &error])
        [CBLUi showMessageDialog:self withTitle:@"Error" withMessage:@"Couldn't delete task list"];
    [self reload];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
