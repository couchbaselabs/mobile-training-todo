//
// ImageService.cs
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
using System.IO;
using System.Threading.Tasks;
using Android.Graphics;
using Android.Util;
using Training.Core;

namespace Training.Android
{
    public class ImageService : IImageService
    {
        private LruCache _cache = new LruCache(50);

        private static Bitmap Square(Bitmap image, float size)
        {
            return global::Android.Media.ThumbnailUtils.ExtractThumbnail(image, (int)size, (int)size);
        }

        public Stream GenerateSolidColor(float size, System.Drawing.Color color, string cacheName)
        {
            if(!String.IsNullOrEmpty(cacheName)) {
                var existing = _cache.Get(new Java.Lang.String(cacheName)) as Bitmap;
                if(existing != null) {
                    var existingStream = new MemoryStream();
                    existing.Compress(Bitmap.CompressFormat.Png, 100, existingStream);
                    return existingStream;
                }
            }

            var conf = Bitmap.Config.Rgb565;
            var bmp = Bitmap.CreateBitmap((int)size, (int)size, conf);
            var canvas = new Canvas(bmp);
            var paint = new Paint {
                Dither = false,
                Color = new Color(color.R, color.G, color.B)
            };

            paint.SetStyle(Paint.Style.FillAndStroke);
            canvas.DrawRect(new Rect(0, 0, (int)size, (int)size), paint);
            if(!String.IsNullOrEmpty(cacheName)) {
                _cache.Put(new Java.Lang.String(cacheName), bmp);
            }

            var memoryStream = new MemoryStream();
            bmp.Compress(Bitmap.CompressFormat.Png, 100, memoryStream);
            return memoryStream;
        }

        public async Task<Stream> Square(Stream image, float size, string cacheName)
        {
            if(image == null || image == Stream.Null) {
                return Stream.Null;
            }

            return await Task.Run<Stream>(() =>
            {
                var bmp = BitmapFactory.DecodeStream(image);
                var square = Square(bmp, size);
                if(!String.IsNullOrEmpty(cacheName)) {
                    _cache.Put(new Java.Lang.String(cacheName), square);
                }

                var memoryStream = new MemoryStream();
                square.Compress(Bitmap.CompressFormat.Png, 100, memoryStream);
                memoryStream.Seek(0, SeekOrigin.Begin);
                return memoryStream;
            });
        }
    }
}

