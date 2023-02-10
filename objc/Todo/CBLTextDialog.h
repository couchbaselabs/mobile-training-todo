//
// CBLTextDialog.h
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

@interface CBLTextDialog : NSObject

@property (nullable, copy, nonatomic) NSString *title;
@property (nullable, copy, nonatomic) NSString *message;
@property (nullable, copy, nonatomic) void (^textFieldConfig)(UITextField *);
@property (nullable, copy, nonatomic) NSString *okButtonTitle;
@property (nonatomic) UIAlertActionStyle okButtonStyle;
@property (nullable, copy, nonatomic) void (^onOkAction)(NSString *);
@property (nullable, copy, nonatomic) NSString *cancelButtonTitle;
@property (nonatomic) UIAlertActionStyle cancelButtonStyle;
@property (nullable, copy, nonatomic) void (^onCancelAction)(void);

- (void)show:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
