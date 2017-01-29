//
//  CBLImage.h
//  Todo
//
//  Created by Pasin Suriyentrakorn on 1/26/17.
//  Copyright © 2017 Pasin Suriyentrakorn. All rights reserved.
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
