//
//  CBLListsViewController.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface CBLListsViewController : UITableViewController

- (void) updateReplicatorStatus: (CBLReplicatorActivityLevel)level;

@end
