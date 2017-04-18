//
//  MediaPicker.cs
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
using System.IO;
using System.Threading.Tasks;
using Windows.Media.Capture;
using Windows.Storage.Pickers;
using Microsoft.Win32;
using XLabs.Platform.Services.Media;

namespace Training.UWP.Services
{
    // An implementation of IMediaPicker for WPF, using OpenFileDialog
    internal sealed class MediaPicker : IMediaPicker
    {

        #region Properties

        public bool IsCameraAvailable
        {
            get => true;
        }

        public bool IsPhotosSupported
        {
            get => true;
        }

        public bool IsVideosSupported
        {
            get => false;
        }

        public EventHandler<MediaPickerErrorArgs> OnError { get; set; }

        public EventHandler<MediaPickerArgs> OnMediaSelected { get; set; }

        #endregion

        #region IMediaPicker

        public async Task<MediaFile> SelectPhotoAsync(CameraMediaStorageOptions options)
        {
            var picker = new FileOpenPicker();
            picker.ViewMode = PickerViewMode.Thumbnail;
            picker.SuggestedStartLocation = PickerLocationId.PicturesLibrary;
            picker.FileTypeFilter.Add(".png");
            picker.FileTypeFilter.Add(".jpg");
            picker.FileTypeFilter.Add(".jpeg");

            var file = await picker.PickSingleFileAsync();
            if (file != null) {
                return new MediaFile(file.Name, () => file.OpenStreamForReadAsync().Result);
            }

            return null;
        }

        public Task<MediaFile> SelectVideoAsync(VideoMediaStorageOptions options)
        {
            throw new NotImplementedException();
        }

        public async Task<MediaFile> TakePhotoAsync(CameraMediaStorageOptions options)
        {
            var captureUI = new CameraCaptureUI();
            captureUI.PhotoSettings.Format = CameraCaptureUIPhotoFormat.Png;
            var photo = await captureUI.CaptureFileAsync(CameraCaptureUIMode.Photo);
            if (photo == null) {
                return null;
            }

            return new MediaFile(photo.Name, () => photo.OpenStreamForReadAsync().Result);
        }

        public Task<MediaFile> TakeVideoAsync(VideoMediaStorageOptions options)
        {
            throw new NotImplementedException();
        }

        #endregion

    }
}
