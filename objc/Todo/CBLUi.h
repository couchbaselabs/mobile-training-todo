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

+ (void)showTextInputDialog:(UIViewController*)controller
                  withTitle:(nullable NSString*)title
                withMessage:(nullable NSString*)message
        withTextFeildConfig:(void (^_Nullable)(UITextField *textField))textFieldConfig
                       onOk:(void (^_Nullable)(NSString *name))onOkAction;

+ (void)showMessageDialog:(UIViewController*)controller
                withTitle:(nullable NSString *)title
              withMessage:(nullable NSString *)message
                withError:(nullable NSError *)error
                  onClose:(void (^_Nullable)(void))oncloseAction;

+ (void)showMessageDialog:(UIViewController *)controller
                withTitle:(NSString *)title
              withMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END


