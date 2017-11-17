//
//  CBLTasksViewController.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLTasksViewController.h"
#import "AppDelegate.h"
#import "CBLConstants.h"
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
    NSArray <CBLQueryResult*> *_taskRows;
    NSString *_taskIDForImage;
    id _dbChangeListener;
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
    // Remove change listener:
    [_database removeChangeListener:_dbChangeListener];
}

#pragma mark - Database

- (void)reload {
    if (!_taskQuery) {
        _taskQuery = [[CBLQuery select:@[S_ID]
                                  from:[CBLQueryDataSource database:_database]
                                 where:[[TYPE equalTo:@"task"]
                                        andExpression: [TASK_LIST_ID equalTo:self.taskList.id]]
                               orderBy:@[[CBLQueryOrdering expression:CREATED_AT],
                                         [CBLQueryOrdering expression:TASK]]] toLive];
        __weak typeof (self) wSelf = self;
        [_taskQuery addChangeListener:^(CBLLiveQueryChange *change) {
            if (!change.rows)
                NSLog(@"Error querying tasks: %@", change.error);
            _taskRows = [change.rows allObjects];
            [wSelf.tableView reloadData];
        }];
    }
    [_taskQuery start];
}

- (void)createTask:(NSString *)task {
    CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
    [doc setObject:@"task" forKey:@"type"];
    NSDictionary *taskList = @{@"id": _taskList.id,
                               @"owner": [_taskList stringForKey: @"owner"]};
    [doc setObject:taskList forKey:@"taskList"];
    [doc setObject:[NSDate date] forKey:@"createdAt"];
    [doc setObject:task forKey:@"task"];
    [doc setObject:@NO forKey:@"complete"];
    
    NSError *error;
    if (![_database saveDocument:doc error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't save task" error:error];
}

- (void)updateTask:(NSString *)taskID withTitle:(NSString *)title {
    CBLMutableDocument *task = [[_database documentWithID: taskID] toMutable];
    [task setObject:title forKey:@"task"];
    
    NSError *error;
    if (![_database saveDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update task" error:error];
}

- (void)updateTask:(NSString *)taskID withComplete:(BOOL)complete {
    CBLMutableDocument *task = [[_database documentWithID: taskID] toMutable];
    [task setObject:@(complete) forKey:@"complete"];
    NSError *error;
    if (![_database saveDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update complete status" error:error];
}

- (void)updateTask:(NSString *)taskID withImage:(UIImage *)image {
    NSError *error;
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    if (!imageData)
        return;
    
    CBLMutableDocument *task = [[_database documentWithID: taskID] toMutable];
    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpg" data:imageData];
    [task setObject:blob forKey:@"image"];
    if (![_database saveDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update task" error:error];
}

- (void)deleteTask:(NSString *)taskID {
    CBLDocument *task = [_database documentWithID: taskID];
    NSError *error;
    if (![_database deleteDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't delete task" error:error];
}

- (void)searchTask: (NSString*)name {
    CBLQueryExpression *exp1 = [TYPE equalTo:@"task"];
    CBLQueryExpression *exp2 = [TASK_LIST_ID equalTo:self.taskList.id];
    CBLQueryExpression *exp3 = [TASK like:[NSString stringWithFormat:@"%%%@%%", name]];
    _searchQuery = [CBLQuery select:@[S_ID]
                               from:[CBLQueryDataSource database:_database]
                              where:[[exp1 andExpression: exp2] andExpression:exp3]
                            orderBy:@[[CBLQueryOrdering expression:CREATED_AT],
                                      [CBLQueryOrdering expression:TASK]]];
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
    
    if (!_dbChangeListener) {
        __weak typeof(self) wSelf = self;
        _dbChangeListener = [_database addChangeListener:^(CBLDatabaseChange *change) {
            for (NSString *docId in change.documentIDs) {
                if ([docId isEqualToString: moderatorDocId]) {
                    [wSelf displayOrHideUsers];
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
    
    NSString* docID = [_taskRows[indexPath.row] stringAtIndex:0];
    CBLDocument *doc = [_database documentWithID:docID];
    
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
            _taskIDForImage = docID;
            [self performSegueWithIdentifier:@"showTaskImage" sender:self];
        };
    } else {
        cell.taskImage = nil;
        cell.taskImageAction = ^() {
            _taskIDForImage = docID;
            [CBLUi showImageActionSheet:self imagePickerDelegate:self onDelete:nil];
        };
    }
    
    return cell;
}

- (void)updateImage:(UIImage *)image withDigest:(NSString *)digest atIndexPath:(NSIndexPath *)indexPath {
    if (_taskRows.count <= indexPath.row)
        return;
    
    NSString* docID = [_taskRows[indexPath.row] stringAtIndex:0];
    CBLDocument *doc = [_database documentWithID:docID];
    CBLBlob *imageBlob = [doc blobForKey: @"image"];
    if ([imageBlob.digest isEqualToString:digest]) {
        CBLTaskTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.taskImage = image;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* docID = [_taskRows[indexPath.row] stringAtIndex:0];
    CBLDocument *doc = [_database documentWithID:docID];
    BOOL complete = ![doc booleanForKey:@"complete"];
    [self updateTask:docID withComplete:complete];
    
    // Optimistically update the UI:
    CBLTaskTableViewCell *cell = (CBLTaskTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = complete ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* docID = [_taskRows[indexPath.row] stringAtIndex:0];
    
    UITableViewRowAction *delete =
        [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                           title:@"Delete"
                                         handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        // Dismiss row actions:
        [tableView setEditing:NO animated:YES];
        // Delete task document:
        [self deleteTask:docID];
    }];
    delete.backgroundColor = [UIColor colorWithRed:1.0 green:0.23 blue:0.19 alpha:1.0];
    
    UITableViewRowAction *update =
        [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                           title:@"Edit"
                                         handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        // Dismiss row actions:
        [tableView setEditing:NO animated:YES];
        
        // Display update list dialog:
        [CBLUi showTextInputOn:self title:@"Edit Task" message:nil textField:^(UITextField *text) {
            CBLDocument *doc = [_database documentWithID:docID];
            text.placeholder = @"Task";
            text.text = [doc stringForKey:@"task"];
            text.autocorrectionType = UITextAutocapitalizationTypeSentences;
        } onOk:^(NSString * name) {
            [self updateTask:docID withTitle:name];
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
    if (_taskIDForImage) {
        [self updateTask:_taskIDForImage withImage:info[@"UIImagePickerControllerOriginalImage"]];
        _taskIDForImage = nil;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTaskImage"]) {
        UINavigationController *navController = segue.destinationViewController;
        CBLTaskImageViewController *controller = (CBLTaskImageViewController*)navController.topViewController;
        controller.taskID = _taskIDForImage;
        _taskIDForImage = nil;
    }
}

@end
