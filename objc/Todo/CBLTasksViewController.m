//
//  CBLTasksViewController.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLTasksViewController.h"
#import "AppDelegate.h"
#import "CBLUi.h"
#import "CBLImage.h"
#import "CBLTaskTableViewCell.h"
#import "CBLTaskImageViewController.h"
#import "CBLSession.h"

@interface CBLTasksViewController () <UISearchResultsUpdating,
                                      UISearchBarDelegate,
                                      UIImagePickerControllerDelegate,
                                      UINavigationControllerDelegate>
{
    UISearchController *_searchController;
    
    NSString *_username;
    CBLDatabase *_database;
    CBLLiveQuery *_taskQuery;
    CBLQuery *_searchQuery;
    NSArray *_taskRows;
    CBLDocument *_taskForImage;
    id _dbChangeObserver;
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
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    // Get database and username:
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _database = app.database;
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

- (void) dealloc {
    if (_dbChangeObserver != nil)
        [NSNotificationCenter.defaultCenter removeObserver: _dbChangeObserver];
}

#pragma mark - Database

- (void)reload {
    if (!_taskQuery) {
        CBLQueryExpression *exp1 = [[CBLQueryExpression property:@"type"] equalTo:@"task"];
        CBLQueryExpression *exp2 = [[CBLQueryExpression property:@"taskList.id"] equalTo:self.taskList.documentID];
        _taskQuery = [[CBLQuery select:[CBLQuerySelect all]
                                  from:[CBLQueryDataSource database:_database]
                                 where:[exp1 and: exp2]
                               orderBy:[CBLQueryOrderBy orderBy:@[[CBLQueryOrderBy property:@"createdAt"],
                                                                  [CBLQueryOrderBy property:@"task"]]]] toLive];
        __weak typeof (self) wSelf = self;
        [_taskQuery addChangeListener:^(CBLLiveQueryChange *change) {
            if (!change.rows)
                NSLog(@"Error querying tasks: %@", change.error);
            _taskRows = [change.rows allObjects];
            [wSelf.tableView reloadData];
        }];
    }
    [_taskQuery run];
}

- (void)createTask:(NSString *)task {
    CBLDocument *doc = [[CBLDocument alloc] init];
    [doc setObject:@"task" forKey:@"type"];
    NSDictionary *taskList = @{@"id": _taskList.documentID,
                               @"owner": [_taskList stringForKey: @"owner"]};
    [doc setObject:taskList forKey:@"taskList"];
    [doc setObject:[NSDate date] forKey:@"createdAt"];
    [doc setObject:task forKey:@"task"];
    [doc setObject:@NO forKey:@"complete"];
    
    NSError *error;
    if (![_database saveDocument:doc error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't save task" error:error];
}

- (void)updateTask:(CBLDocument *)task withTitle:(NSString *)title {
    [task setObject:title forKey:@"task"];
    
    NSError *error;
    if (![_database saveDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update task" error:error];
}

- (void)updateTask:(CBLDocument *)task withComplete:(BOOL)complete {
    [task setObject:@(complete) forKey:@"complete"];
    NSError *error;
    if (![_database saveDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update complete status" error:error];
}

- (void)updateTask:(CBLDocument *)task withImage:(UIImage *)image {
    NSError *error;
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    if (!imageData)
        return;
    
    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpg" data:imageData];
    [task setObject:blob forKey:@"image"];
    if (![_database saveDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update task" error:error];
}

- (void)deleteTask:(CBLDocument *)task {
    NSError *error;
    if (![_database deleteDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't delete task" error:error];
}

- (void)searchTask: (NSString*)name {
    CBLQueryExpression *exp1 = [[CBLQueryExpression property:@"type"] equalTo:@"task"];
    CBLQueryExpression *exp2 = [[CBLQueryExpression property:@"taskList.id"] equalTo:self.taskList.documentID];
    CBLQueryExpression *exp3 = [[CBLQueryExpression property:@"task"] like:[NSString stringWithFormat:@"%%%@%%", name]];
    _searchQuery = [CBLQuery select:[CBLQuerySelect all]
                               from:[CBLQueryDataSource database:_database]
                              where:[[exp1 and: exp2] and:exp3]
                            orderBy:[CBLQueryOrderBy orderBy:@[[CBLQueryOrderBy property:@"createdAt"],
                                                               [CBLQueryOrderBy property:@"task"]]]];
    NSError *error;
    NSEnumerator *rows = [_searchQuery run: &error];
    if (!rows)
        NSLog(@"Error searching tasks: %@", error);
    
    _taskRows = [rows allObjects];
    [self.tableView reloadData];
}

#pragma mark - Users

- (void) displayOrHideUsers {
    BOOL display = NO;
    NSString *moderatorDocId = [NSString stringWithFormat:@"moderator.%@", _username];
    if ([_username isEqualToString: [_taskList stringForKey:@"owner"]])
        display = YES;
    else
        display = [_database contains:moderatorDocId];
    [CBLUi displayOrHideTabbar:self display:display];
    
    if (!_dbChangeObserver) {
        [NSNotificationCenter.defaultCenter addObserverForName:kCBLDatabaseChangeNotification
                                                        object:_database
                                                         queue:nil
                                                    usingBlock:^(NSNotification * _Nonnull note)
        {
            CBLDatabaseChange *change = [note.userInfo objectForKey: kCBLDatabaseChangesUserInfoKey];
            for (NSString *docId in change.documentIDs) {
                if ([docId isEqualToString: moderatorDocId]) {
                    [self displayOrHideUsers];
                    break;
                }
            }
        }];
    }
}

#pragma mark - Actions

- (IBAction)addAction:(id)sender {
    [CBLUi showTextInputOn:self title:@"New Task" message:nil textField:^(UITextField *text) {
        text.placeholder = @"Task";
        text.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } onOk:^(NSString *name) {
        [self createTask:name];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _taskRows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CBLTaskTableViewCell *cell =
        (CBLTaskTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TaskCell"
                                                                forIndexPath:indexPath];
    
    CBLDocument *doc = ((CBLQueryRow *)_taskRows[indexPath.row]).document;
    cell.taskLabel.text = [doc stringForKey: @"task"];
    
    BOOL complete = [doc booleanForKey:@"complete"];
    cell.accessoryType = complete ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    CBLBlob *imageBlob = [doc blobForKey: @"image"];
    if (imageBlob) {
        UIImage *image = [UIImage imageWithData:imageBlob.content scale:[UIScreen mainScreen].scale];
        NSString *digest = imageBlob.digest;
        UIImage *thumbnail = [CBLImage square:image
                                     withSize:44.0
                                withCacheName:digest
                                   onComplete:^(UIImage *result) {
            [self updateImage:result withDigest:digest atIndexPath:indexPath];
        }];
        cell.taskImage = thumbnail;
        cell.taskImageAction = ^() {
            _taskForImage = doc;
            [self performSegueWithIdentifier:@"showTaskImage" sender:self];
        };
    } else {
        cell.taskImage = nil;
        cell.taskImageAction = ^() {
            _taskForImage = doc;
            [CBLUi showImageActionSheet:self imagePickerDelegate:self onDelete:nil];
        };
    }
    
    return cell;
}

- (void)updateImage:(UIImage *)image withDigest:(NSString *)digest atIndexPath:(NSIndexPath *)indexPath {
    if (_taskRows.count <= indexPath.row)
        return;
    
    CBLDocument *doc = ((CBLQueryRow *)_taskRows[indexPath.row]).document;
    CBLBlob *imageBlob = [doc blobForKey: @"image"];
    if ([imageBlob.digest isEqualToString:digest]) {
        CBLTaskTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.taskImage = image;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBLDocument *doc = ((CBLQueryRow *)_taskRows[indexPath.row]).document;
    BOOL complete = ![doc booleanForKey:@"complete"];
    [self updateTask:doc withComplete:complete];
    
    // Optimistically update the UI:
    CBLTaskTableViewCell *cell = (CBLTaskTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = complete ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *delete =
        [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                           title:@"Delete"
                                         handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        // Dismiss row actions:
        [tableView setEditing:NO animated:YES];
        // Delete task document:
        CBLDocument *doc = ((CBLQueryRow *)_taskRows[indexPath.row]).document;
        [self deleteTask:doc];
    }];
    delete.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    
    UITableViewRowAction *update =
        [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                           title:@"Edit"
                                         handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        // Dismiss row actions:
        [tableView setEditing:NO animated:YES];
        // Display update list dialog:
        CBLDocument *doc = ((CBLQueryRow *)_taskRows[indexPath.row]).document;
        
        [CBLUi showTextInputOn:self title:@"Edit Task" message:nil textField:^(UITextField *text) {
            text.placeholder = @"Task";
            text.text = [doc stringForKey:@"task"];
            text.autocorrectionType = UITextAutocapitalizationTypeSentences;
        } onOk:^(NSString * name) {
            [self updateTask:doc withTitle:name];
        }];
    }];
    update.backgroundColor = [UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0];
    
    return @[delete, update];
}

#pragma mark - UISearchController

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text ?: @"";
    if ([text length] > 0) {
        [_taskQuery stop];
        [self searchTask:text];
    } else
        [self reload];
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    if (_taskForImage) {
        [self updateTask:_taskForImage withImage:info[@"UIImagePickerControllerOriginalImage"]];
        _taskForImage = nil;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTaskImage"]) {
        UINavigationController *navController = segue.destinationViewController;
        CBLTaskImageViewController *controller = (CBLTaskImageViewController*)navController.topViewController;
        controller.task = _taskForImage;
        _taskForImage = nil;
    }
}

@end
