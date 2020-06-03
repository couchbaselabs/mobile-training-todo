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
    
    CBLQuery *_taskQuery;
    NSArray <CBLQueryResult*> *_taskRows;
    
    CBLQuery *_searchQuery;
    BOOL _inSearch;
    NSArray <CBLQueryResult*> *_searchRows;
    
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
    _searchController.searchBar.delegate = self;
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
    [_database removeChangeListenerWithToken:_dbChangeListener];
}

#pragma mark - Database

- (void)reload {
    if (!_taskQuery) {
        _taskQuery = [CBLQueryBuilder select:@[S_ID, S_TASK, S_COMPLETE, S_IMAGE]
                                        from:[CBLQueryDataSource database:_database]
                                       where:[[TYPE equalTo:[CBLQueryExpression string:@"task"]]
                                              andExpression: [TASK_LIST_ID equalTo:[CBLQueryExpression string:self.taskList.id]]]
                                     orderBy:@[[CBLQueryOrdering expression:CREATED_AT],
                                               [CBLQueryOrdering expression:TASK]]];
        __weak typeof (self) wSelf = self;
        [_taskQuery addChangeListener:^(CBLQueryChange *change) {
            if (!change.results)
                NSLog(@"Error querying tasks: %@", change.error);
            _taskRows = [change.results allObjects];
            [wSelf.tableView reloadData];
        }];
    }
}

- (void)createTask:(NSString *)task {
    CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
    [doc setValue:@"task" forKey:@"type"];
    NSDictionary *taskList = @{@"id": _taskList.id,
                               @"owner": [_taskList stringForKey: @"owner"]};
    [doc setValue:taskList forKey:@"taskList"];
    [doc setValue:[NSDate date] forKey:@"createdAt"];
    [doc setValue:task forKey:@"task"];
    [doc setValue:@NO forKey:@"complete"];
    
    NSError *error;
    if (![_database saveDocument:doc error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't save task" error:error];
}

- (void)updateTask:(NSString *)taskID withTitle:(NSString *)title {
    CBLMutableDocument *task = [[_database documentWithID: taskID] toMutable];
    [task setValue:title forKey:@"task"];
    
    NSError *error;
    if (![_database saveDocument:task error:&error])
        [CBLUi showErrorOn:self message:@"Couldn't update task" error:error];
}

- (void)updateTask:(NSString *)taskID withComplete:(BOOL)complete {
    CBLMutableDocument *task = [[_database documentWithID: taskID] toMutable];
    [task setBoolean:complete forKey:@"complete"];
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
    [task setValue:blob forKey:@"image"];
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
    CBLQueryExpression *exp1 = [TYPE equalTo:[CBLQueryExpression string:@"task"]];
    CBLQueryExpression *exp2 = [TASK_LIST_ID equalTo:[CBLQueryExpression string:self.taskList.id]];
    CBLQueryExpression *exp3 = [TASK like:[CBLQueryExpression string:[NSString stringWithFormat:@"%%%@%%", name]]];
    _searchQuery = [CBLQueryBuilder select:@[S_ID, S_TASK, S_COMPLETE, S_IMAGE]
                                      from:[CBLQueryDataSource database:_database]
                                     where:[[exp1 andExpression: exp2] andExpression:exp3]
                                   orderBy:@[[CBLQueryOrdering expression:CREATED_AT],
                                             [CBLQueryOrdering expression:TASK]]];
    NSError *error;
    NSEnumerator *rows = [_searchQuery execute: &error];
    if (!rows)
        NSLog(@"Error searching tasks: %@", error);
    
    _searchRows = [rows allObjects];
    [self.tableView reloadData];
}

#pragma mark - Users

- (void) displayOrHideUsers {
    BOOL display = NO;
    NSString *moderatorDocId = [NSString stringWithFormat:@"moderator.%@", _username];
    if ([_username isEqualToString: [_taskList stringForKey:@"owner"]])
        display = YES;
    else
        display = [_database documentWithID:moderatorDocId] != nil;
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

- (NSArray<CBLQueryResult*>*)data {
    return _inSearch ? _searchRows : _taskRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CBLTaskTableViewCell *cell =
        (CBLTaskTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TaskCell"
                                                                forIndexPath:indexPath];
    
    CBLQueryResult* result = self.data[indexPath.row];
    NSString* docID = [result stringAtIndex:0];
    
    cell.taskLabel.text = [result stringAtIndex: 1];
    
    BOOL complete = [result booleanAtIndex: 2];
    cell.accessoryType = complete ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    CBLBlob *imageBlob = [result blobAtIndex: 3];
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
    
    NSLog(@"[Task#%ld] %@ : %@", (long)indexPath.row, docID, [result stringAtIndex: 1]);
    
    return cell;
}

- (void)updateImage:(UIImage *)image withDigest:(NSString *)digest atIndexPath:(NSIndexPath *)indexPath {
    if (self.data.count <= indexPath.row)
        return;
    
    NSString* docID = [self.data[indexPath.row] stringAtIndex:0];
    CBLDocument *doc = [_database documentWithID:docID];
    CBLBlob *imageBlob = [doc blobForKey: @"image"];
    if ([imageBlob.digest isEqualToString:digest]) {
        CBLTaskTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.taskImage = image;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* docID = [self.data[indexPath.row] stringAtIndex:0];
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
    NSString* docID = [self.data[indexPath.row] stringAtIndex:0];
    
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
        _inSearch = YES;
        [self searchTask:text];
    } else {
        [self searchBarCancelButtonClicked: searchController.searchBar];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _inSearch = NO;
    _searchRows = nil;
    [self.tableView reloadData];
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    if (_taskIDForImage) {
        [self updateTask:_taskIDForImage withImage:info[@"UIImagePickerControllerOriginalImage"]];
        _taskIDForImage = nil;
    }
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
