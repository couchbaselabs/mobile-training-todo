//
//  CBLTaskTableViewCell.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLTaskTableViewCell.h"

@implementation CBLTaskTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setTaskImage:(UIImage *)taskImage {
    [self.imageButton setImage:taskImage forState:UIControlStateNormal];
}

- (IBAction)imageButtonAction:(id)sender {
    if (self.taskImageAction)
        self.taskImageAction();
}

@end
