//
//  TaskImage.swift
//  Todo
//
//  Created by Callum Birks on 20/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI

// Used to create an image from blob
struct TaskImage {
    // Images are cached to prevent slowdown from Images being loaded and unloaded
    static let cache = NSCache<AnyObject, AnyObject>()
    
    static func create(taskID: String) -> Image? {
        guard let taskDoc = try? DB.shared.getTaskByID(id: taskID)
        else {
            return nil
        }
        guard let blob = taskDoc?.blob(forKey: "image"),
              let content = blob.content
        else {
            return nil
        }
        // Try and get image from cache
        if let key = blob.digest, !key.isEmpty,
           let cachedImage = cache.object(forKey: key as AnyObject) as? UIImage {
            return Image(uiImage: cachedImage)
        }
        // If image was not in cache, load it from blob
        guard let uiImage = UIImage(data: content)
        else {
            return nil
        }
        DispatchQueue.global().async {
            if let key = blob.digest, !key.isEmpty {
                cache.setObject(uiImage, forKey: key as AnyObject)
            }
        }
        return Image(uiImage: uiImage)
    }
}
