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
                       onOk:(void (^_Nullable)(NSString *name))onOkAction
{
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
                  onClose:(void (^_Nullable)(void))onCloseAction
{
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
        if (onCloseAction)
            onCloseAction();
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

+ (void)showErrorDialog:(UIViewController*)controller
            withMessage:(nullable NSString *)message
              withError:(nullable NSError *)error
{
    [CBLUi showMessageDialog:controller
                   withTitle:@"Error"
                 withMessage:message
                   withError:error
                     onClose:nil];
}

+ (void)showImageActionSheet:(UIViewController *)controller
     wihtImagePickerDelegate:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
                    onDelete:(void (^_Nullable)(void))onDeleteAction
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Take Photo"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            [self showImagePicker:controller
                   withSourceType:UIImagePickerControllerSourceTypeCamera
               withPickerDelegate:delegate];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Choose Existing"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
            [self showImagePicker:controller
                   withSourceType:UIImagePickerControllerSourceTypePhotoLibrary
               withPickerDelegate:delegate];
    }]];
    
    if (onDeleteAction ) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
            onDeleteAction();
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) { }]];
    
    [controller presentViewController:alert animated:YES completion:nil];
}

+ (void)showImagePicker:(UIViewController *)controller
         withSourceType:(UIImagePickerControllerSourceType)sourceType
     withPickerDelegate: (id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.delegate = delegate;
    [controller presentViewController:imagePicker animated:YES completion:nil];
}

@end
