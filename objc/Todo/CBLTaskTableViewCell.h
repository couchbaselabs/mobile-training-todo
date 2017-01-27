//
//  CBLTaskTableViewCell.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBLTaskTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UILabel *taskLabel;
@property (nullable, nonatomic) UIImage* taskImage;
@property (nullable, copy, nonatomic) void (^taskImageAction)();

@end

NS_ASSUME_NONNULL_END
