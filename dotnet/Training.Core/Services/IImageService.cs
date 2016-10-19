//
// IImageService.cs
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
using System.Drawing;
using System.IO;
using System.Threading.Tasks;

namespace Training.Core
{
    /// <summary>
    /// A service that will crop and resize an image to a square of a given size
    /// </summary>
    public interface IImageService
    {
        /// <summary>
        /// Crop the given image data to a square and reduce it to the given size.
        /// </summary>
        /// <param name="image">The image data to work with.</param>
        /// <param name="size">The size to reduce to.</param>
        /// <param name="cacheName">The ID for the cache to store the result in.</param>
        /// <returns>An awaitable task that will contain a stream of data containing the result
        /// of the operation upon completion</returns>
        Task<byte[]> Square(Stream image, float size, string cacheName);

        /// <summary>
        /// Generates a solid square of the given color and size
        /// </summary>
        /// <returns>The PNG data of the generated image</returns>
        /// <param name="size">The size of the square to generate</param>
        /// <param name="color">The color of the square to generate.</param>
        /// <param name="cacheName">The ID to cache the generated value as.</param>
        byte[] GenerateSolidColor(float size, Color color, string cacheName);
    }
}

