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
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: true forKey: HAS_SETTINGS_KEY];
    
    [defaults setBool: self.loggingSwitch.on forKey: IS_LOGGING_KEY];
    [defaults setBool: self.loginFlowSwitch.on forKey: IS_LOGIN_FLOW_KEY];
    [defaults setBool: self.syncSwitch.on forKey: IS_SYNC_KEY];
    [defaults setBool: self.pushNotificationSwitch.on forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
    [defaults setBool: self.ccrSwitch.on forKey: IS_CCR_ENABLED_KEY];
    [defaults setInteger: self.ccrSegmentedControl.selectedSegmentIndex forKey: CCR_TYPE_KEY];
    [defaults setValue: self.maxRetries.text forKey: MAX_RETRY_KEY];
    [defaults setValue: self.maxRetryWaitTime.text forKey: MAX_RETRY_WAIT_TIME_KEY];
    
    NSString* url = self.syncEndpoint.text;
    if (url) {
        // save the url to config
    }
        
    
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
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    assert([defaults boolForKey: HAS_SETTINGS_KEY]);
    
    self.loggingSwitch.on = [defaults boolForKey: IS_LOGGING_KEY];
    self.loginFlowSwitch.on = [defaults boolForKey: IS_LOGIN_FLOW_KEY];
    self.syncSwitch.on = [defaults boolForKey: IS_SYNC_KEY];
    self.pushNotificationSwitch.on = [defaults boolForKey: IS_PUSH_NOTIFICATION_ENABLED_KEY];
    self.ccrSwitch.on = [defaults boolForKey: IS_CCR_ENABLED_KEY];
    self.ccrSegmentedControl.selectedSegmentIndex = [defaults integerForKey: CCR_TYPE_KEY];
    self.maxRetries.text = [defaults stringForKey: MAX_RETRY_KEY];
    self.maxRetryWaitTime.text = [defaults stringForKey: MAX_RETRY_WAIT_TIME_KEY];
}

@end
