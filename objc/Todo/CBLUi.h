//
// CBLUi.h
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

+ (void)displayOrHideTabbar:(UIViewController*)controller display:(BOOL)display;

@end

NS_ASSUME_NONNULL_END


