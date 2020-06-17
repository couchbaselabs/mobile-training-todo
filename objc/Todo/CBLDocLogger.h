//
//  CBLDocLogger.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 6/16/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBLDocLogger : NSObject

+ (void)logTaskList:(CBLDocument*)doc inDatabase: (CBLDatabase*)database;

+ (void)logTask:(CBLDocument*)doc;

@end

NS_ASSUME_NONNULL_END
