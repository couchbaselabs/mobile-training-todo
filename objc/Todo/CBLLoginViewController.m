//
//  CBLLoginViewController.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 5/30/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLLoginViewController.h"
#import "CBLUi.h"

@interface CBLLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation CBLLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _usernameTextField.text = self.username;
}

- (IBAction)loginAction:(id)sender {
    NSString* username = _usernameTextField.text != nil ? _usernameTextField.text : @"";
    username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString* password = _passwordTextField.text != nil ? _passwordTextField.text : @"";
    password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (username.length == 0 || password.length == 0) {
        [CBLUi showMessageOn:self
                       title:@"Error"
                     message:@"Username and password cannot be empty"
                       error:nil
                     onClose:nil];
        return;
    }
    
    if ([_delegate respondsToSelector:@selector(login:withUsername:password:)])
        [_delegate login:self withUsername:username password:password];
}

@end
