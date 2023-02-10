//
// CBLImage.m
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

#import "CBLImage.h"

@implementation CBLImage

+ (UIImage *)square:(UIImage *)image
           withSize:(CGFloat)size
      withCacheName:(NSString *)name
         onComplete:(void (^_Nullable)(UIImage *result))completeAction
{
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 50;
    });
    
    id cachedImage = [cache objectForKey:name];
    if (cachedImage)
        return cachedImage;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *square = [image squareImageWithSize:size];
        dispatch_async(dispatch_get_main_queue(), ^{
            [cache setObject:square forKey:name];
            if (completeAction)
                completeAction(square);
        });
    });
    
    return nil;
}

@end

@implementation UIImage (Square)

- (nullable UIImage *)squareImageWithSize:(CGFloat)size {
    return [[self squareImage] resizeToSize:CGSizeMake(size, size)];
}

- (nullable UIImage *)squareImage {
    CGFloat oWidth = CGImageGetWidth(self.CGImage);
    CGFloat oHeight = CGImageGetHeight(self.CGImage);
    CGFloat sqSize = MIN(oWidth, oHeight);
    CGFloat x = (oWidth - sqSize) / 2.0;
    CGFloat y = (oHeight - sqSize) / 2.0;
    CGRect rect = CGRectMake(x, y, sqSize, sqSize);
    CGImageRef sqImage = CGImageCreateWithImageInRect(self.CGImage, rect);
    return [UIImage imageWithCGImage:sqImage scale:self.scale orientation:self.imageOrientation];
}

- (nullable UIImage *)resizeToSize:(CGSize)newSize {
    CGFloat oWidth = self.size.width;
    CGFloat oHeight = self.size.height;
    CGFloat wRatio = newSize.width / oWidth;
    CGFloat hRatio = newSize.height / oHeight;
    
    CGSize nuSize;
    if (wRatio > hRatio)
        nuSize = CGSizeMake(oWidth * hRatio, oHeight * hRatio);
    else
        nuSize = CGSizeMake(oWidth * wRatio, oHeight * wRatio);
    CGRect rect = CGRectMake(0, 0, nuSize.width, nuSize.height);
    
    UIGraphicsBeginImageContextWithOptions(nuSize, NO, self.scale);
    [self drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
