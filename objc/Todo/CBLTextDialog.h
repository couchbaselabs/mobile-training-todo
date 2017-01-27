//
//  CBLTextDialog.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
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
@property (nullable, copy, nonatomic) void (^onCancelAction)();

- (void)show:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
