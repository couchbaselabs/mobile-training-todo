//
//  CBLTaskDetailViewController.m
//  Todo
//
//  Created by Jayahari Vavachan on 3/29/21.
//  Copyright © 2021 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLTaskDetailViewController.h"
#import "AppDelegate.h"
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLTaskDetailViewController () {
    CBLDatabase* _database;
    CBLDocument* _task;
}

@property (weak, nonatomic) IBOutlet UILabel* taskName;
@property (weak, nonatomic) IBOutlet UISwitch* completeSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl* segmentedControl;
@property (weak, nonatomic) IBOutlet UITextView* textView;
@property (weak, nonatomic) IBOutlet UITextField* keyTextField;
@property (weak, nonatomic) IBOutlet UITextField* valueTextField;

@end

@implementation CBLTaskDetailViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _database = app.database;
    _task = [_database documentWithID: self.taskID];
    
    [self updateUI];
}

#pragma mark - Button Actions

- (IBAction) closeAction: (id)sender {
    [self dismissViewControllerAnimated: true completion: nil];
}

- (IBAction) segmentedControlValueChanged: (id)sender {
    [self updateUI];
}

- (IBAction) switchChanged: (id)sender {
    [self updateTask: @(((UISwitch*)sender).on) forKey: @"complete"];
}

- (IBAction) setKeyValue: (id)sender {
    NSString* value = self.valueTextField.text;
    NSString* key = self.keyTextField.text;
    if (value && value.length > 0 && key && key.length)
        [self updateTask: value forKey: key];
    
}

#pragma mark - Helper functions

- (void) updateTask: (id)value forKey: (NSString*)key {
    CBLMutableDocument* mTask = [_task toMutable];
    [mTask setValue: value forKey: key];
    
    NSError* error;
    [_database saveDocument: mTask error: &error];
    
    _task = [_database documentWithID: _taskID];
    [self updateUI];
}

- (void) updateUI {
    self.completeSwitch.on = [_task booleanForKey: @"complete"];
    self.taskName.text = [_task stringForKey: @"task"];
    if (self.segmentedControl.selectedSegmentIndex == 0)
        self.textView.text = [NSString stringWithFormat: @"%@", [_task toDictionary]];
    else
        self.textView.text = [NSString stringWithFormat: @"%@", [_task toJSON]];
}

@end
