//
//  Image.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/15/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import Foundation

extension UIImage {
    func square(size: CGFloat) -> UIImage? {
        return square()?.resize(CGSizeMake(size, size))
    }
    
    func square() -> UIImage? {
        let oWidth = CGFloat(CGImageGetWidth(self.CGImage))
        let oHeight = CGFloat(CGImageGetHeight(self.CGImage))
        let sqSize = min(oWidth, oHeight)
        let x = (oWidth - sqSize) / 2.0
        let y = (oHeight - sqSize) / 2.0
        let rect = CGRectMake(x, y, sqSize, sqSize)
        let sqImage = CGImageCreateWithImageInRect(self.CGImage, rect)
        return UIImage(CGImage: sqImage!, scale: self.scale, orientation: self.imageOrientation)
    }
    
    func resize(newSize: CGSize) -> UIImage? {
        let oWidth = self.size.width
        let oHeight = self.size.height
        let wRatio = newSize.width  / oWidth
        let hRatio = newSize.height / oHeight
        
        var nuSize: CGSize
        if(wRatio > hRatio) {
            nuSize = CGSizeMake(oWidth * hRatio, oHeight * hRatio)
        } else {
            nuSize = CGSizeMake(oWidth * wRatio, oHeight * wRatio)
        }
        let rect = CGRectMake(0, 0, nuSize.width, nuSize.height)

        UIGraphicsBeginImageContextWithOptions(nuSize, false, self.scale)
        self.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

class Image {
    private static let cache = NSCache()
    private static var token: dispatch_once_t = 0
    
    class func square(image: UIImage?, withSize size: CGFloat, withCacheName name: String?,
        onComplete action: ((UIImage?) -> Void)?) -> UIImage? {
            dispatch_once(&token) {
                cache.countLimit = 50
            }
            
            guard let oImage = image else {
                return nil
            }
            
            if let key = name where !key.isEmpty {
                if let cachedImage = cache.objectForKey(key) as? UIImage {
                    return cachedImage
                }
            }
            
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                let square = oImage.square(size)
                dispatch_async(dispatch_get_main_queue()) {
                    if let key = name, cachedImage = square where !key.isEmpty {
                        cache.setObject(cachedImage, forKey: key)
                    }
                    if let complete = action {
                        complete(square)
                    }
                }
            }
            
            return nil
    }
}