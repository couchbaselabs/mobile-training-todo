//
//  CBLUsersViewController.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 6/15/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBLUsersViewController : UITableViewController

@property (nonatomic) CBLDocument *taskList;

@end

NS_ASSUME_NONNULL_END
