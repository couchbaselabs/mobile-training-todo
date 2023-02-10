//
// CBLLoginViewController.h
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

#import <UIKit/UIKit.h>

@protocol CBLLoginViewControllerDelegate;

@interface CBLLoginViewController : UIViewController

@property (nonatomic) id <CBLLoginViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString* username;

@end

@protocol CBLLoginViewControllerDelegate <NSObject>
- (void) login: (CBLLoginViewController*)controller username: (NSString*)username
      password: (NSString*)password;
@end

