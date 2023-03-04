//
// TaskImage.swift
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

import SwiftUI

// Used to create an image from blob
struct TaskImage {
    // Images are cached to prevent slowdown from Images being loaded and unloaded
    static let cache = NSCache<AnyObject, AnyObject>()
    
    static func create(task: Task) -> Image? {
        guard let blob = task.image else {
            return nil
        }
        
        // Try and get image from cache
        if let cachedImage = cache.object(forKey: blob.digest() as AnyObject) as? UIImage {
            return Image(uiImage: cachedImage)
        }
        
        // If image was not in cache, load it from blob
        guard let uiImage = UIImage(data: blob.content()) else {
            return nil
        }
        
        // Cache image
        DispatchQueue.global().async {
            cache.setObject(uiImage, forKey: blob.digest() as AnyObject)
        }
        
        return Image(uiImage: uiImage)
    }
}
