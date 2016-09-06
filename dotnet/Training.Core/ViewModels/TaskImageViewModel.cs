//
// TaskImageViewModel.cs
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
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using XLabs.Platform.Services.Media;

namespace Training.Core
{
    /// <summary>
    /// The view model for the page that displays a task's image
    /// </summary>
    public class TaskImageViewModel : BaseViewModel<TaskImageModel>
    {
        private ImageChooser _imageChooser;

        public ICommand EditCommand
        {
            get {
                return new MvxAsyncCommand(EditImage);
            }
        }
        /// <summary>
        /// Gets the stream containing the image data
        /// </summary>
        /// <value>The image.</value>
        public Stream Image
        {
            get {
                return Model.Image ?? Stream.Null;
            }
            set {
                Model.Image = value;
                RaisePropertyChanged();
            }
        }

        public TaskImageViewModel(IUserDialogs dialogs, IMediaPicker mediaPicker)
        {
            _imageChooser = new ImageChooser(new ImageChooserConfig {
                Dialogs = dialogs,
                MediaPicker = mediaPicker,
                DeleteText = "Delete"
            });
        }

        /// <summary>
        /// Initializes the view model with data passed to it
        /// </summary>
        /// <param name="databaseName">The name of the database</param>
        /// <param name="documentID">The ID of the task document</param>
        public void Init(string databaseName, string documentID)
        {
            Model = new TaskImageModel(databaseName, documentID);
        }

        private async Task EditImage()
        {
            var result = await _imageChooser.GetPhotoAsync();
            if(result == null) {
                return;
            }

            if(result == Stream.Null) {
                result = null;
            }

            Image = result;
        }
    }
}

