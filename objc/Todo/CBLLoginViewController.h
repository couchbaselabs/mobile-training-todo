//
//  CBLLoginViewController.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 5/30/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CBLLoginViewControllerDelegate;

@interface CBLLoginViewController : UIViewController

@property (nonatomic) id <CBLLoginViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString* username;

@end

@protocol CBLLoginViewControllerDelegate <NSObject>
- (void) login: (CBLLoginViewController*)controller withUsername: (NSString*)username
      password: (NSString*)password;
@end

