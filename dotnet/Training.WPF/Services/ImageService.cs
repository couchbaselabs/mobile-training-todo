//
//  ImageService.cs
//
//  Author:
//  	Jim Borden  <jim.borden@couchbase.com>
//
//  Copyright (c) 2016 Couchbase, Inc All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.Caching;
using System.Threading.Tasks;

using Training.Core;

namespace Training.WPF.Services
{
    // An implementation of IImageService using ObjectCache and System.Drawing
    internal sealed class ImageService : IImageService
    {

        #region Variables

        private ObjectCache _cache = MemoryCache.Default;

        #endregion

        #region Private API

        private Bitmap Shrink(Image src, float size)
        {
            var width = src.Width;
            var height = src.Height;
            var sqSize = Math.Min(width, height);
            var x = (width - sqSize) / 2;
            var y = (height - sqSize) / 2;
            var bmPhoto = new Bitmap((int)size, (int)size, PixelFormat.Format24bppRgb);
            bmPhoto.SetResolution(src.HorizontalResolution,
                             src.VerticalResolution);

            var grPhoto = Graphics.FromImage(bmPhoto);
            grPhoto.Clear(Color.Blue);
            grPhoto.InterpolationMode = InterpolationMode.HighQualityBicubic;

            grPhoto.DrawImage(src,
                new Rectangle(0, 0, (int)size, (int)size),
                new Rectangle(x, y, sqSize, sqSize),
                GraphicsUnit.Pixel);

            grPhoto.Dispose();
            return bmPhoto;
        }

        private byte[] GetExisting(string cacheName)
        {
            if(!String.IsNullOrEmpty(cacheName)) {
                var cachedObject = _cache[cacheName] as byte[];
                if(cachedObject != null) {
                    return cachedObject;
                }
            }

            return null;
        }

        private byte[] Put(string cacheName, Bitmap image)
        {
            byte[] data;
            using(var ms = new MemoryStream()) {
                image.Save(ms, ImageFormat.Png);
                data = ms.ToArray();
            }
            if(!String.IsNullOrEmpty(cacheName)) {
                _cache[cacheName] = data;
            }

            return data;
        }

        #endregion

        #region IImageService

        public byte[] GenerateSolidColor(float size, Color color, string cacheName)
        {
            var bmp = new Bitmap((int)size, (int)size, PixelFormat.Format24bppRgb);
            using(var g = Graphics.FromImage(bmp)) {
                g.FillRectangle(new SolidBrush(color), 0, 0, bmp.Width, bmp.Height);
            }

            return Put(cacheName, bmp);
        }

        public async Task<byte[]> Square(Stream image, float size, string cacheName)
        {
            if(image == null || image == Stream.Null) {
                return null;
            }

            var existing = GetExisting(cacheName);
            if(existing != null) {
                return existing;
            }

            return await Task.Run(() =>
            {
                var imageObj = Image.FromStream(image);
                var square = Shrink(imageObj, size);
                return Put(cacheName, square);
            });
        }

        #endregion
 
    }
}
