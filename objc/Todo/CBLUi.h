//
//  CBLUI.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBLUi : NSObject

+ (void)showTextInputOn:(UIViewController *)controller
                  title:(nullable NSString *)title
                message:(nullable NSString *)message
              textField:(void (^_Nullable)(UITextField *textField))config
                   onOk:(void (^_Nullable)(NSString *name))onOkAction;

+ (void)showMessageOn:(UIViewController *)controller
                title:(nullable NSString *)title
              message:(nullable NSString *)message
                error:(nullable NSError *)error
              onClose:(void (^_Nullable)(void))onCloseAction;

+ (void)showErrorOn:(UIViewController *)controller
            message:(nullable NSString *)message
              error:(nullable NSError *)error;

+ (void)showImageActionSheet:(UIViewController *)controller
         imagePickerDelegate:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
                    onDelete:(void (^_Nullable)(void))onDeleteAction;

@end

NS_ASSUME_NONNULL_END


