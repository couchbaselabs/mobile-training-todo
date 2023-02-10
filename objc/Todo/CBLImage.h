//
// CBLImage.h
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

NS_ASSUME_NONNULL_BEGIN

@interface CBLImage : NSObject

+ (nullable UIImage *)square:(UIImage *)image
                    withSize:(CGFloat)size
               withCacheName:(NSString *)name
                  onComplete:(void (^_Nullable)(UIImage *result))completeAction;

@end

@interface UIImage (Square)

- (nullable UIImage *)squareImageWithSize:(CGFloat)size;

- (nullable UIImage *)squareImage;

- (nullable UIImage *)resizeToSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
