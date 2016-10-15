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
    /// <summary>
    /// An implementation of IImageService using LruCache, Bitmap, and Canvas
    /// </summary>
    public class ImageService : IImageService
    {

        #region Variables

        private static LruCache _cache = new LruCache(50);

        #endregion

        #region Private API

        private static Bitmap Square(Bitmap image, float size)
        {
            return global::Android.Media.ThumbnailUtils.ExtractThumbnail(image, (int)size, (int)size);
        }

        private byte[] GetExisting(string cacheName)
        {
            if(!String.IsNullOrEmpty(cacheName)) {
                var existing = _cache.Get(new Java.Lang.String(cacheName)) as ByteArrayWrapper;
                if(existing != null) {
                    return existing.Bytes;
                }
            }

            return null;
        }

        private byte[] Put(string cacheName, Bitmap bmp)
        {
            var memoryStream = new MemoryStream();
            bmp.Compress(Bitmap.CompressFormat.Png, 100, memoryStream);
            var bytes = memoryStream.ToArray();

            if(!String.IsNullOrEmpty(cacheName)) {
                _cache.Put(new Java.Lang.String(cacheName), new ByteArrayWrapper(bytes));
            }

            return bytes;
        }

        #endregion

        #region IImageService

        public byte[] GenerateSolidColor(float size, System.Drawing.Color color, string cacheName)
        {
            var existing = GetExisting(cacheName);
            if(existing != null) {
                return existing;
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

            return await Task.Run<byte[]>(() =>
            {
                var bmp = BitmapFactory.DecodeStream(image);
                if(bmp == null) {
                    return null;
                }

                var square = Square(bmp, size);
                return Put(cacheName, square);
            });
        }

        #endregion
    }

    // Thin wrapper for storing bytes in a collection that holds Java objects
    internal sealed class ByteArrayWrapper : Java.Lang.Object
    {
        #region Properties

        public byte[] Bytes { get; }

        #endregion

        #region Public API

        public ByteArrayWrapper(byte[] bytes)
        {
            Bytes = bytes;
        }

        #endregion
    }
}

