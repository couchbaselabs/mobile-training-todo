//
// CBLLoginViewController.m
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
    username = [username stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    NSString* password = _passwordTextField.text != nil ? _passwordTextField.text : @"";
    password = [password stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    if (username.length == 0 || password.length == 0) {
        [CBLUi showMessageOn: self
                       title: @"Error"
                     message: @"Username and password cannot be empty"
                       error: nil
                     onClose: nil];
        return;
    }
    
    if ([_delegate respondsToSelector: @selector(login:username:password:)])
        [_delegate login: self username: username password: password];
}

@end
