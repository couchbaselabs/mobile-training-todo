//
// CBLSettingsViewController.m
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

#import "CBLSettingsViewController.h"
#import "CBLConfig.h"
#import "AppDelegate.h"

@interface CBLSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField* syncEndpoint;
@property (weak, nonatomic) IBOutlet UISwitch* loggingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* syncSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* pushNotificationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* ccrSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl* ccrSegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField* maxAttempts;
@property (weak, nonatomic) IBOutlet UITextField* maxAttemptWaitTime;

@property (weak, nonatomic) IBOutlet UIStackView* syncBackground;
@property (weak, nonatomic) IBOutlet UIStackView* ccrBackground;
@property (weak, nonatomic) IBOutlet UIStackView* maxAttemptBackground;

@end

@implementation CBLSettingsViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self loadSavedValues];
}

#pragma mark - Button Actions

- (IBAction) onCancel:(id)sender {
    [self dismissViewControllerAnimated: true completion: nil];
}

- (IBAction) onSave:(id)sender {
    CBLConfig.shared.loggingEnabled = self.loggingSwitch.on;
    CBLConfig.shared.syncEnabled = self.syncSwitch.on;
    CBLConfig.shared.pushNotificationEnabled = self.pushNotificationSwitch.on;
    CBLConfig.shared.ccrEnabled = self.ccrSwitch.on;
    CBLConfig.shared.ccrType = self.ccrSegmentedControl.selectedSegmentIndex;
    CBLConfig.shared.maxAttempts = self.maxAttempts.text.doubleValue;
    CBLConfig.shared.maxAttemptWaitTime = self.maxAttemptWaitTime.text.doubleValue;
    CBLConfig.shared.syncEndpoint = self.syncEndpoint.text;
    
    [CBLConfig.shared save];
    
    [self dismissViewControllerAnimated: true completion:^{
        [(AppDelegate *)[UIApplication sharedApplication].delegate logout: CBLLogoutModeCloseDatabase];
    }];
}

#pragma mark - Helper functions

- (void) setupUI {
    self.syncBackground.layer.borderColor = UIColor.blackColor.CGColor;
    self.syncBackground.layer.borderWidth = 0.1;
    self.syncBackground.layer.cornerRadius = 5;
    self.ccrBackground.layer.borderColor = UIColor.blackColor.CGColor;
    self.ccrBackground.layer.borderWidth = 0.1;
    self.ccrBackground.layer.cornerRadius = 5;
    self.maxAttemptBackground.layer.borderColor = UIColor.blackColor.CGColor;
    self.maxAttemptBackground.layer.borderWidth = 0.1;
    self.maxAttemptBackground.layer.cornerRadius = 5;
}

- (void) loadSavedValues {
    self.syncEndpoint.text = [CBLConfig shared].syncEndpoint;
    
    self.loggingSwitch.on = CBLConfig.shared.loggingEnabled;
    self.syncSwitch.on = CBLConfig.shared.syncEnabled;
    self.pushNotificationSwitch.on = CBLConfig.shared.pushNotificationEnabled;
    self.ccrSwitch.on = CBLConfig.shared.ccrEnabled;
    self.ccrSegmentedControl.selectedSegmentIndex = CBLConfig.shared.ccrType;
    self.maxAttempts.text = [NSString stringWithFormat:@"%ld", (long)CBLConfig.shared.maxAttempts];
    self.maxAttemptWaitTime.text = [NSString stringWithFormat:@"%ld", CBLConfig.shared.maxAttemptWaitTime];
}

@end
