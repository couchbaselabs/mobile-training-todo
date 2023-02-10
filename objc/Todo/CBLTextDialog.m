//
// CBLTextDialog.m
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

#import "CBLTextDialog.h"

@implementation CBLTextDialog

- (void)show:(UIViewController *)controller {
    id observer = nil;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.title
                                                                   message:self.message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // OK:
    NSString *okTitle = self.okButtonTitle ?: @"OK";
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle
                                                       style:self.okButtonStyle
                                                     handler:
                               ^(UIAlertAction * _Nonnull action) {
                                   UITextField *textField = alert.textFields[0];
                                   if(observer)
                                       [[NSNotificationCenter defaultCenter] removeObserver:observer];
                                   NSString *text = textField.text;
                                   if (self.onOkAction && text)
                                       self.onOkAction(text);
                               }];
    [okAction setEnabled:NO];
    [alert addAction:okAction];
    
    // Cancel:
    NSString *cancelTitle = self.cancelButtonTitle ?: @"Cancel";
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle
                                                           style:self.cancelButtonStyle
                                                         handler:
                                   ^(UIAlertAction * _Nonnull action) {
                                       if(observer)
                                           [[NSNotificationCenter defaultCenter] removeObserver:observer];
                                       if (self.onCancelAction)
                                           self.onCancelAction();
                                   }];
    [okAction setEnabled:NO];
    [alert addAction:cancelAction];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        if (self.textFieldConfig)
            self.textFieldConfig(textField);
        [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification
                                                          object:textField
                                                           queue:nil
                                                      usingBlock:
         ^(NSNotification * _Nonnull note) {
             [okAction setEnabled:(textField.text != nil)];
         }];
    }];
    
    [alert.view setNeedsLayout];
    [controller presentViewController:alert animated:YES completion:nil];
}

@end
