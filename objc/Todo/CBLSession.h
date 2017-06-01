//
//  CBLSession.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 5/30/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBLSession : NSObject

@property (nonatomic, copy) NSString* username;

+ (instancetype) sharedInstance;

@end
