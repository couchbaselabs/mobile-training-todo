//
//  CBLTasksViewController.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBLTasksViewController : UITableViewController

@property (nonatomic) CBLDocument *taskList;

@end

NS_ASSUME_NONNULL_END
