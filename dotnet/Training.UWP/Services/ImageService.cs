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
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Threading.Tasks;
using Windows.Graphics.Imaging;
using Windows.Storage.Streams;
using Windows.UI.Xaml.Controls;
using Microsoft.Extensions.Caching.Memory;
using Training.Core;
using Plugin.Media;

namespace Training.UWP.Services
{
    [ComImport]
    [Guid("5B0D3235-4DBA-4D44-865E-8F1D0E4FD04D")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    unsafe interface IMemoryBufferByteAccess
    {
        void GetBuffer(out byte* buffer, out uint capacity);
    }

    // An implementation of IImageService using ObjectCache and System.Drawing
    internal sealed class ImageService : IImageService
    {

        #region Variables

        private MemoryCache _cache = new MemoryCache(new MemoryCacheOptions
        {
            CompactOnMemoryPressure = true
        });

        #endregion

        #region Private API

        //private async Task<InMemoryRandomAccessStream> Shrink(IRandomAccessStream src, float size)
        //{
        //    var srcDecode = await BitmapDecoder.CreateAsync(src);
        //    var width = srcDecode.PixelWidth;
        //    var height = srcDecode.PixelHeight;
        //    var sqSize = Math.Min(width, height);
        //    var ratio = size / sqSize;
        //    var ms = new InMemoryRandomAccessStream();
        //    var transcoder = await BitmapEncoder.CreateForTranscodingAsync(ms, srcDecode);
        //    transcoder.BitmapTransform.ScaledWidth = (uint)Math.Round(width * ratio);
        //    transcoder.BitmapTransform.ScaledHeight = (uint)Math.Round(height * ratio);
        //    transcoder.BitmapTransform.InterpolationMode = BitmapInterpolationMode.Linear;
        //    var x = (uint)(transcoder.BitmapTransform.ScaledWidth - sqSize * ratio) / 2;
        //    var y = (uint)(transcoder.BitmapTransform.ScaledHeight - sqSize * ratio) / 2;
        //    transcoder.BitmapTransform.Bounds = new BitmapBounds
        //    {
        //        X = x,
        //        Y = y,
        //        Width = (uint)size,
        //        Height = (uint)size
        //    };
        //    await transcoder.FlushAsync();
        //    return ms;
        //}

        private byte[] GetExisting(string cacheName)
        {
            if (!String.IsNullOrEmpty(cacheName)) {
                var cachedObject = _cache.Get<byte[]>(cacheName);
                if (cachedObject != null) {
                    return cachedObject;
                }
            }

            return null;
        }

        //private async Task<byte[]> Put(string cacheName, SoftwareBitmap image)
        //{
        //    byte[] data;
        //    using (var ms = new InMemoryRandomAccessStream()) {
        //        var encoder = await BitmapEncoder.CreateAsync(BitmapEncoder.PngEncoderId, ms);
        //        encoder.SetSoftwareBitmap(image);
        //        await encoder.FlushAsync();
        //        data = new byte[ms.Size];
        //        await ms.ReadAsync(data.AsBuffer(), (uint)ms.Size, InputStreamOptions.None);
        //    }

        //    if (!String.IsNullOrEmpty(cacheName)) {
        //        _cache.Set(cacheName, data);
        //    }

        //    return data;
        //}

        #endregion

        #region IImageService

        public async Task<byte[]> Square(Stream image, string cacheName)
        {
            if (image == null || image == Stream.Null) {
                return null;
            }

            var existing = GetExisting(cacheName);
            if (existing != null) {
                return existing;
            }

            return GetBytesFromStream(image) ?? null;
        }

        byte[] GetBytesFromStream(Stream stream)
        {
            using (var ms = new MemoryStream()) {
                stream.CopyTo(ms);
                return ms.ToArray();
            }
        }

        #endregion

    }
}
