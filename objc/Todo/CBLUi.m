//
//  CBLUi.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLUi.h"
#import "CBLTextDialog.h"

@implementation CBLUi

+ (void)showTextInputDialog:(UIViewController*)controller
                  withTitle:(nullable NSString*)title
                withMessage:(nullable NSString*)message
        withTextFeildConfig:(void (^_Nullable)(UITextField *textField))textFieldConfig
                       onOk:(void (^_Nullable)(NSString *name))onOkAction {
    CBLTextDialog *dialog = [[CBLTextDialog alloc] init];
    dialog.title = title;
    dialog.message = message;
    dialog.textFieldConfig = textFieldConfig;
    dialog.onOkAction = onOkAction;
    [dialog show:controller];
}

+ (void)showMessageDialog:(UIViewController*)controller
                withTitle:(nullable NSString *)title
              withMessage:(nullable NSString *)message
                withError:(nullable NSError *)error
                  onClose:(void (^_Nullable)(void))oncloseAction {
    NSString *mesg = nil;
    if (error) {
        mesg = [NSString stringWithFormat:@"%@\n\n%@", message, error.localizedDescription];
        NSLog(@"Error: %@ (error=%@)", message, error);
    } else
        mesg = message;
    
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:
    ^(UIAlertAction * _Nonnull action) {
        if (oncloseAction)
            oncloseAction();
    }]];
    [controller presentViewController:alert animated:YES completion:nil];
}

+ (void)showMessageDialog:(UIViewController *)controller
                withTitle:(NSString *)title
              withMessage:(NSString *)message {
    [CBLUi showMessageDialog:controller
                   withTitle:title
                 withMessage:message
                   withError:nil
                     onClose:nil];
}

@end
