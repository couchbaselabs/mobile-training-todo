//
//  CBLSettingsViewController.m
//  Todo
//
//  Created by Jayahari Vavachan on 3/29/21.
//  Copyright © 2021 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLSettingsViewController.h"
#import "CBLConstants.h"
#import "AppDelegate.h"
#import "CBLConfig.h"

@interface CBLSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField* syncEndpoint;
@property (weak, nonatomic) IBOutlet UISwitch* loggingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* loginFlowSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* syncSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* pushNotificationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* ccrSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl* ccrSegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField* maxRetries;
@property (weak, nonatomic) IBOutlet UITextField* maxRetryWaitTime;

@property (weak, nonatomic) IBOutlet UIStackView* syncBackground;
@property (weak, nonatomic) IBOutlet UIStackView* ccrBackground;
@property (weak, nonatomic) IBOutlet UIStackView* maxRetryBackground;

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
    CBLConfig.shared.loginFlowEnabled = self.loginFlowSwitch.on;
    CBLConfig.shared.syncEnabled = self.syncSwitch.on;
    CBLConfig.shared.pushNotificationEnabled = self.pushNotificationSwitch.on;
    CBLConfig.shared.ccrEnabled = self.ccrSwitch.on;
    CBLConfig.shared.ccrType = self.ccrSegmentedControl.selectedSegmentIndex;
    CBLConfig.shared.maxAttempts = self.maxRetries.text.doubleValue;
    CBLConfig.shared.maxAttemptWaitTime = self.maxRetryWaitTime.text.doubleValue;
    CBLConfig.shared.syncEndpoint = self.syncEndpoint.text;
    
    [CBLConfig.shared persist];
    
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
    self.maxRetryBackground.layer.borderColor = UIColor.blackColor.CGColor;
    self.maxRetryBackground.layer.borderWidth = 0.1;
    self.maxRetryBackground.layer.cornerRadius = 5;
}

- (void) loadSavedValues {
    self.syncEndpoint.text = [CBLConfig shared].syncEndpoint;
    
    self.loggingSwitch.on = CBLConfig.shared.loggingEnabled;
    self.loginFlowSwitch.on = CBLConfig.shared.loginFlowEnabled;
    self.syncSwitch.on = CBLConfig.shared.syncEnabled;
    self.pushNotificationSwitch.on = CBLConfig.shared.pushNotificationEnabled;
    self.ccrSwitch.on = CBLConfig.shared.ccrEnabled;
    self.ccrSegmentedControl.selectedSegmentIndex = CBLConfig.shared.ccrType;
    self.maxRetries.text = [NSString stringWithFormat:@"%ld", (long)CBLConfig.shared.maxAttempts];
    self.maxRetryWaitTime.text = [NSString stringWithFormat:@"%ld", CBLConfig.shared.maxAttemptWaitTime];
}

@end
