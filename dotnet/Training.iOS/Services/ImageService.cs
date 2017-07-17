//
// Image.cs
//
// Author:
// 	Jim Borden  <jim.borden@couchbase.com>
//
// Copyright (c) 2016 Couchbase, Inc All rights reserved.
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
using System;
using System.Drawing;
using System.IO;
using System.Threading.Tasks;

using CoreGraphics;
using Foundation;
using Training.Core;
using UIKit;

namespace Training.iOS
{
    /// <summary>
    /// Implementation of IImageService using UIImage, CoreGraphics, and NSCache
    /// </summary>
    public sealed class ImageService : IImageService
    {

        #region Variables

        private static NSCache _cache = new NSCache { CountLimit = 50 };

        #endregion

        #region Private API

        private static UIImage Square(UIImage image, float size)
        {
            var width = (float)image.CGImage.Width;
            var height = (float)image.CGImage.Height;
            var sqSize = Math.Min(width, height);
            var x = (width - sqSize) / 2.0;
            var y = (height - sqSize) / 2.0;
            var rect = new CGRect(x, y, sqSize, sqSize);
            var sqImage = image.CGImage.WithImageInRect(rect);
            return UIImage.FromImage(sqImage);
        }

        private static UIImage Resize(UIImage image, CGSize size)
        {
            var width = image.Size.Width;
            var height = image.Size.Height;
            var wRatio = size.Width / width;
            var hRatio = size.Height / height;

            var nuSize = default(CGSize);
            if(wRatio > hRatio) {
                nuSize = new CGSize(width * hRatio, height * hRatio);
            } else {
                nuSize = new CGSize(width * wRatio, height * wRatio);
            }

            var rect = new CGRect(0, 0, nuSize.Width, nuSize.Height);
            UIGraphics.BeginImageContextWithOptions(nuSize, false, image.CurrentScale);
            image.Draw(rect);
            var newImage = UIGraphics.GetImageFromCurrentImageContext();
            UIGraphics.EndImageContext();

            return newImage;
        }

        private byte[] GetExisting(string cacheName)
        {
            if(!String.IsNullOrEmpty(cacheName)) {
                var cachedObject = _cache.ObjectForKey(new NSString(cacheName)) as NSData;
                if(cachedObject != null) {
                    return cachedObject.ToArray();
                }
            }

            return null;
        }

        private byte[] Put(string cacheName, UIImage image)
        {
            var data = image.AsPNG();
            if(!String.IsNullOrEmpty(cacheName)) {
                _cache.SetObjectforKey(data, new NSString(cacheName));
            }

            return data.ToArray();
        }

        #endregion

        #region IImageService

        public async Task<byte[]> Square(Stream image, float size, string cacheName)
        {
            if(image == null || image == Stream.Null) {
                return null;
            }

            var existing = GetExisting(cacheName);
            if(existing != null) {
                return existing;
            }

            return await Task.Run<byte[]>(() =>
            {
                var uiImage = UIImage.LoadFromData(NSData.FromStream(image));
                var square = Square(uiImage, size);
                square = Resize(square, new CGSize(size, size));
                return Put(cacheName, square);
            });
        }

        public byte[] GenerateSolidColor(float size, Color color, string cacheName)
        {
            var existing = GetExisting(cacheName);
            if(existing != null) {
                return existing;
            }

            UIGraphics.BeginImageContextWithOptions(new CGSize(size, size), true, 1);
            UIGraphics.GetCurrentContext().SetFillColor(new CGColor(color.R / 255.0f, color.G / 255.0f, color.B / 255.0f));
            UIGraphics.RectFill(new CGRect(0, 0, size, size));
            var image = UIGraphics.GetImageFromCurrentImageContext();
            UIGraphics.EndImageContext();

            return Put(cacheName, image);
        }

        #endregion

    }
}

