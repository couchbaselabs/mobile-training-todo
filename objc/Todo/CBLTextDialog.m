//
//  CBLTextDialog.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
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
        if (self.onOkAction && text) {
            self.onOkAction(text);
        }
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
