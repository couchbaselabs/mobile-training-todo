//
//  CBLSession.m
//  Todo
//
//  Created by Pasin Suriyentrakorn on 5/30/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
//

#import "CBLSession.h"

@implementation CBLSession

+ (instancetype) sharedInstance {
    static CBLSession *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

@end
