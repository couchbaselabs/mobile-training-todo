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

+ (void)showTextInputOn:(UIViewController *)controller
                  title:(nullable NSString *)title
                message:(nullable NSString *)message
              textField:(void (^_Nullable)(UITextField *textField))config
                   onOk:(void (^_Nullable)(NSString *name))onOkAction
{
    CBLTextDialog *dialog = [[CBLTextDialog alloc] init];
    dialog.title = title;
    dialog.message = message;
    dialog.textFieldConfig = config;
    dialog.onOkAction = onOkAction;
    [dialog show:controller];
}

+ (void)showMessageOn:(UIViewController *)controller
                title:(nullable NSString *)title
              message:(nullable NSString *)message
                error:(nullable NSError *)error
              onClose:(void (^_Nullable)(void))onCloseAction
{
    NSString *mesg = nil;
    if (error) {
        mesg = [NSString stringWithFormat:@"%@\n\n%@", message, error.localizedDescription];
        NSLog(@"Error: %@ (error=%@)", message, error);
    } else
        mesg = message;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                if (onCloseAction)
                                                    onCloseAction();
                                            }]];
    [controller presentViewController:alert animated:YES completion:nil];
}

+ (void)showMessageOn:(UIViewController *)controller
                title:(NSString *)title
              message:(NSString *)message
{
    [CBLUi showMessageOn:controller title:title message:message error:nil onClose:nil];
}

+ (void)showErrorOn:(UIViewController *)controller
            message:(nullable NSString *)message
              error:(nullable NSError *)error
{
    [CBLUi showMessageOn:controller title:@"Error" message:message error:error onClose:nil];
}

+ (void)showImageActionSheet:(UIViewController *)controller
         imagePickerDelegate:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
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
                                                               sourceType:UIImagePickerControllerSourceTypeCamera
                                                                 delegate:delegate];
                                                }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Choose Existing"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self showImagePicker:controller
                                                           sourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                             delegate:delegate];
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
             sourceType:(UIImagePickerControllerSourceType)sourceType
               delegate:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.delegate = delegate;
    [controller presentViewController:imagePicker animated:YES completion:nil];
}

+ (void)displayOrHideTabbar:(UIViewController*)controller display:(BOOL)display {
    UITabBar* tabBar = controller.tabBarController.tabBar;
    if (!tabBar)
        return;
    
    if (display == tabBar.isHidden) {
        tabBar.hidden = !display;
        if (tabBar.isHidden) {
            controller.tabBarController.selectedIndex = 0;
        }
        
        // Workaround for resizing table view:
        if ([controller isKindOfClass: [UITableViewController class]]) {
            UITableViewController* tableViewController = (UITableViewController*)controller;
            UITableView* tableView = tableViewController.tableView;
            if (display) {
                tableView.frame = CGRectMake(tableView.frame.origin.x,
                                             tableView.frame.origin.y,
                                             tableView.frame.size.width,
                                             tableView.frame.size.height - tabBar.frame.size.height);
            } else {
                tableView.frame = CGRectMake(tableView.frame.origin.x,
                                             tableView.frame.origin.y,
                                             tableView.frame.size.width,
                                             tableView.frame.size.height + tabBar.frame.size.height);
            }
        }
    }
}

@end
