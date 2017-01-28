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

@interface CBLTasksViewController () <UISearchResultsUpdating,
                                      UIImagePickerControllerDelegate,
                                      UINavigationControllerDelegate>
{
    UISearchController *_searchController;
    
    CBLDatabase *_database;
    CBLQuery *_taskQuery;
    CBLQuery *_searchQuery;
    NSArray* _taskRows;
    CBLDocument *_taskForImage;
}

@end

@implementation CBLTasksViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup Search Controller:
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    // Get database:
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _database = app.database;
    
    // Load data:
    [self reload];
}

#pragma mark - Database

- (void)reload {
    NSError *error;
    if (!_taskQuery) {
        NSString *where = [NSString stringWithFormat:@"type == 'task' AND taskList.id == '%@'",
                       self.taskList.documentID];
        _taskQuery = [_database createQueryWhere:where
                                         orderBy:@[@"createdAt", @"task"]
                                       returning:nil
                                           error:&error];
        if (!_taskQuery) {
            NSLog(@"Error creating a query: %@", error);
            return;
        }
    }
    
    NSEnumerator *rows = [_taskQuery run: &error];
    if (!rows)
        NSLog(@"Error querying tasks: %@", error);
    _taskRows = [rows allObjects];
    
    [self.tableView reloadData];
}

- (void)createTask:(NSString *)task {
    CBLDocument *doc = [_database document];
    doc[@"type"] = @"task";
    doc[@"taskList"] = @{@"id": _taskList.documentID, @"owner": _taskList[@"owner"]};
    doc[@"createdAt"] = [NSDate date];
    doc[@"task"] = task;
    doc[@"complete"] = @NO;
    
    NSError *error;
    if ([doc save: &error])
        [self reload];
    else
        [CBLUi showErrorDialog:self withMessage:@"Couldn't save task" withError:error];
}

- (void)updateTask:(CBLDocument *)task withTitle:(NSString *)title {
    task[@"task"] = title;
    NSError *error;
    if ([task save: &error])
        [self reload];
    else
        [CBLUi showErrorDialog:self withMessage:@"Couldn't update task" withError:error];
}

- (void)updateTask:(CBLDocument *)task withComplete:(BOOL)complete {
    task[@"complete"] = @(complete);
    NSError *error;
    if ([task save: &error])
        [self reload];
    else
        [CBLUi showErrorDialog:self withMessage:@"Couldn't update complete status" withError:error];
}

- (void)updateTask:(CBLDocument *)task withImage:(UIImage *)image {
    NSError *error;
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    if (!imageData)
        return;
    
    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpg" data:imageData error:nil];
    task[@"image"] = blob;
    if ([task save: &error])
        [self reload];
    else
        [CBLUi showErrorDialog:self withMessage:@"Couldn't update task" withError:error];
}

- (void)deleteTask:(CBLDocument *)task {
    NSError *error;
    if ([task deleteDocument:&error])
        [self reload];
    else
        [CBLUi showErrorDialog:self withMessage:@"Couldn't delete task" withError:error];
}

- (void)searchTask: (NSString*)name {
    NSError *error;
    if (!_searchQuery) {
        NSString *where = [NSString stringWithFormat:
                           @"type == 'task' AND taskList.id == '%@' AND task contains[c] $NAME",
                           self.taskList.documentID];
        _searchQuery = [_database createQueryWhere:where
                                           orderBy:@[@"createdAt", @"task"]
                                         returning:nil
                                             error:&error];
        if (!_searchQuery) {
            NSLog(@"Error creating a query: %@", error);
            return;
        }
    }
    
    _searchQuery.parameters = @{@"NAME": name};
    NSEnumerator *rows = [_searchQuery run: &error];
    if (!rows)
        NSLog(@"Error searching tasks: %@", error);
    
    _taskRows = [rows allObjects];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)addAction:(id)sender {
    [CBLUi showTextInputDialog:self
                     withTitle:@"New Task"
                   withMessage:nil
           withTextFeildConfig:^(UITextField *textField) {
               textField.placeholder = @"Task";
               textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
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
    cell.taskLabel.text = doc[@"task"];
    
    BOOL complete = [doc booleanForKey:@"complete"];
    cell.accessoryType = complete ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    CBLBlob *imageBlob = doc[@"image"];
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
            [CBLUi showImageActionSheet:self wihtImagePickerDelegate:self onDelete:nil];
        };
    }
    
    return cell;
}

- (void)updateImage:(UIImage *)image withDigest:(NSString *)digest atIndexPath:(NSIndexPath *)indexPath {
    if (_taskRows.count <= indexPath.row)
        return;
    
    CBLDocument *doc = ((CBLQueryRow *)_taskRows[indexPath.row]).document;
    CBLBlob *imageBlob = doc[@"image"];
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
        
        [CBLUi showTextInputDialog:self withTitle:@"Edit Task"
                       withMessage:nil withTextFeildConfig:^(UITextField *textField) {
            textField.placeholder = @"Task";
            textField.text = doc[@"task"];
            textField.autocorrectionType = UITextAutocapitalizationTypeSentences;
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
    if ([text length] > 0)
        [self searchTask:text];
    else
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
