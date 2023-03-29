//
// CBLSGAdmin.m
//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "CBLSGAdmin.h"
#import "CBLConfig.h"

NSErrorDomain const CBLSGErrorDomain = @"CBLSGErrorDomain";

@interface CBLSGAdmin () <NSURLSessionTaskDelegate>
    
@end
    
@implementation CBLSGAdmin 

+ (instancetype) shared {
    static CBLSGAdmin* _shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ _shared = [[self alloc] init]; });
    return _shared;
}

- (instancetype) init {
    return [super init];
}

- (void) createRole: (NSString*)role completion: (void (^)(bool success, NSError* error))completionHandler {
    NSDictionary* body = @{
        @"name": role,
        @"_default": @{
            @"lists": @{@"admin_channels": @[]},
            @"tasks": @{@"admin_channels": @[]},
            @"users": @{@"admin_channels": @[]}
        }
    };
    
    [self sendJSONRequestWithMethod: @"POST" path: @"_role" body: body completion: ^(NSData* data, NSURLResponse* response, NSError* e) {
        NSError *err = nil;
        NSString* tag = [NSString stringWithFormat: @"Create role '%@'", role];
        BOOL success = [self checkErrorFor: tag  response: response error: e outError: &err];
        completionHandler(success, err);
    }];
}

// MARK: Utils

- (NSURL*) adminURLForPath: (NSString*)path {
    NSURLComponents* comps = [NSURLComponents componentsWithString: CBLConfig.shared.syncEndpoint];
    comps.scheme = [comps.scheme isEqualToString: @"was"] ? @"https" : @"http";
    comps.port = @(CBLConfig.shared.syncAdminPort);
    comps.path = [comps.path stringByAppendingPathComponent: path];
    if ([path hasSuffix: @"/"] && ![comps.path hasSuffix: @""]) {
        comps.path = [comps.path stringByAppendingString: @"/"];
    }
    return [comps URL];
}

- (NSString*) adminAuthHeader {
    NSString* auth = [NSString stringWithFormat: @"%@:%@",
                      CBLConfig.shared.syncAdminUsername, CBLConfig.shared.syncAdminPassword];
    NSString* authBase64 = [[auth dataUsingEncoding: NSUTF8StringEncoding] base64EncodedStringWithOptions: 0];
    return [NSString stringWithFormat:@"Basic %@", authBase64];
}

- (void) sendJSONRequestWithMethod: (NSString*)method path: (NSString*)path body: (NSDictionary*)body
                        completion: (void (^)(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error))completion {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL: [self adminURLForPath: path]];
    request.HTTPMethod = method;
    [request setValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
    [request setValue: @"application/json" forHTTPHeaderField: @"Accept"];
    [request setValue: [self adminAuthHeader] forHTTPHeaderField: @"Authorization"];
    
    if (body) {
        NSData* jsonBody = [NSJSONSerialization dataWithJSONObject: body options: 0 error: nil];
        NSAssert(jsonBody, @"Invalid JSON");
        [request setHTTPBody: jsonBody];
    }
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration: config delegate: self delegateQueue: nil];
    NSURLSessionDataTask* task = [session dataTaskWithRequest: request completionHandler: ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        completion(data, response, error);
    }];
    [task resume];
}

- (void) URLSession: (NSURLSession *)session task:( NSURLSessionTask *)task willPerformHTTPRedirection: (NSHTTPURLResponse *)response
         newRequest: (NSURLRequest *)request completionHandler: (void (^)(NSURLRequest * _Nullable))completion {
    NSMutableURLRequest* rediect = [task.originalRequest mutableCopy];
    rediect.URL = request.URL;
    completion(rediect);
}

- (NSInteger) statusCodeForResponse: (NSURLResponse*)response {
    return ((NSHTTPURLResponse*) response).statusCode;
}

- (BOOL) isStatusOK: (NSInteger) statusCode {
    return statusCode >= 200 && statusCode < 300;
}

- (BOOL) checkErrorFor: (NSString*)name response: (nullable NSURLResponse*)response error: (nullable NSError*)error outError: (NSError**)outError {
    if (error) {
        NSLog(@"[Todo] %@ Error: %@", name, error);
        if (outError) {
            *outError = error;
        }
        return NO;
    }
    
    NSInteger status = [self statusCodeForResponse: response];
    BOOL ok = [self isStatusOK: status];
    NSLog(@"[Todo] %@ Status %@ : %ld", name, (ok ? @"Success" : @"Error"), (long)status);
    if (!ok) {
        if (outError) {
            *outError = [NSError errorWithDomain: CBLSGErrorDomain code: status userInfo: nil];
        }
    }
    return ok;
}

@end
