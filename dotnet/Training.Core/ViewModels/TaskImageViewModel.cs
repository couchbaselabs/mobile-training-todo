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
using Acr.UserDialogs;
using Couchbase.Lite;
using Robo.Mvvm.Input;
using Robo.Mvvm.Services;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Input;

using Training.Core;
using Training.Models;

namespace Training.ViewModels
{
    /// <summary>
    /// The view model for the page that displays a task's image
    /// </summary>
    public class TaskImageViewModel : BaseNavigationViewModel
    {

        #region Variables

        private Document _taskDocument;
        private ImageChooser _imageChooser;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the command to handle an edit request
        /// </summary>
        public ICommand EditCommand => new Command(async() => await EditImage());

        /// <summary>
        /// The image stored on the task
        /// </summary>
        /// <value>The image.</value>
        public byte[] Image
        {
            get => _taskDocument.GetBlob("image")?.Content;
            set {
                using (var mutableTask = _taskDocument.ToMutable()) {
                    if (value == null) {
                        mutableTask.Remove("image");
                    } else {
                        mutableTask.SetBlob("image", new Blob("image/png", value));
                    }

                    CoreApp.Database.Save(mutableTask);
                    _taskDocument = mutableTask;
                }
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor (not to be called directly)
        /// </summary>
        /// <param name="dialogs">The interface responsible for showing dialogs.</param>
        /// <param name="mediaPicker">The interface responsible for getting photos.</param>
        public TaskImageViewModel(INavigationService navigation, IUserDialogs dialogs, IMediaService mediaPicker)
            :base(navigation, dialogs)
        {
            _imageChooser = new ImageChooser(new ImageChooserConfig
            {
                Dialogs = dialogs,
                MediaPicker = mediaPicker,
                DeleteText = "Delete"
            });
        }

        #endregion

        #region Public API

        /// <summary>
        /// Initializes the view model with data passed to it
        /// </summary>
        /// <param name="documentID">The ID of the task document</param>
        public void Init(string documentID)
        {
            _taskDocument = CoreApp.Database.GetDocument(documentID);
        }

        #endregion

        #region Private API

        private async Task EditImage()
        {
            var result = await _imageChooser.GetPhotoAsync();
            if(result == null) {
                return;
            }

            Image = result;
        }

        #endregion

    }
}

