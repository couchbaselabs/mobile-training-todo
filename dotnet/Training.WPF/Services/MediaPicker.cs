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

using Microsoft.Win32;
using XLabs.Platform.Services.Media;

namespace Training.WPF.Services
{
    // An implementation of IMediaPicker for WPF, using OpenFileDialog
    internal sealed class MediaPicker : IMediaPicker
    {

        #region Properties

        public bool IsCameraAvailable
        {
            get {
                return false;
            }
        }

        public bool IsPhotosSupported
        {
            get {
                return true;
            }
        }

        public bool IsVideosSupported
        {
            get {
                return false;
            }
        }

        public EventHandler<MediaPickerErrorArgs> OnError { get; set; }

        public EventHandler<MediaPickerArgs> OnMediaSelected { get; set; }

        #endregion

        #region IMediaPicker

        public Task<MediaFile> SelectPhotoAsync(CameraMediaStorageOptions options)
        {
            var dlg = new OpenFileDialog {
                Title = "Select Photo For Task"
            };

            var result = dlg.ShowDialog();
            if(result == true) {
                var filename = dlg.FileName;
                return Task.FromResult(new MediaFile(filename, () => File.OpenRead(filename)));
            }

            return Task.FromResult<MediaFile>(null);
        }

        public Task<MediaFile> SelectVideoAsync(VideoMediaStorageOptions options)
        {
            throw new NotImplementedException();
        }

        public Task<MediaFile> TakePhotoAsync(CameraMediaStorageOptions options)
        {
            throw new NotImplementedException();
        }

        public Task<MediaFile> TakeVideoAsync(VideoMediaStorageOptions options)
        {
            throw new NotImplementedException();
        }

        #endregion

    }
}
