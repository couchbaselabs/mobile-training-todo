//
// TaskCellModel.cs
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
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;

using Acr.UserDialogs;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;

namespace Training.Core
{
    /// <summary>
    /// The model for a cell in the list on the Tasks page
    /// </summary>
    public sealed class TaskCellModel : BaseViewModel<TaskModel>
    {
        private IUserDialogs _dialogs = Mvx.Resolve<IUserDialogs>();
        private Lazy<string> _imageDigest;

        public ICommand DeleteCommand
        {
            get {
                return new MvxCommand(Delete);
            }
        }

        public ICommand EditCommand
        {
            get {
                return new MvxAsyncCommand(Edit);
            }
        }

        public string DocumentID { get; }

        /// <summary>
        /// Gets the name of the task
        /// </summary>
        public string Name
        {
            get {
                return _name.Value;
            }
        }
        private Lazy<string> _name;

        /// <summary>
        /// Gets the thumbnail of the image stored with the task, if it exists
        /// </summary>
        public Stream Thumbnail
        {
            get {
                return _thumbnail;
            }
            private set {
                SetProperty(ref _thumbnail, value);
            }
        }
        private Stream _thumbnail;

        /// <summary>
        /// Gets or sets whether or not the task is checked
        /// </summary>
        public bool IsChecked 
        {
            get {
                return Model.IsChecked;
            }
            set {
                if(Model.IsChecked == value) {
                    return;
                }

                try {
                    Model.IsChecked = value;
                } catch(Exception e) {
                    _dialogs.ShowError(e.Message);
                    return;
                }

                RaisePropertyChanged(nameof(CheckedImage));
            }
        }

        public string CheckedImage
        {
            get {
                return IsChecked ? "Checkmark.png" : null;
            }
        }

        private ICommand _addImageCommand;
        public ICommand AddImageCommand
        {
            get {
                return _addImageCommand;
            }
            set {
                SetProperty(ref _addImageCommand, value);
            }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="databaseName">The name of the database</param>
        /// <param name="documentID">The ID of the document to use</param>
        public TaskCellModel(string databaseName, string documentID)
        {
            DocumentID = documentID;
            Model = new TaskModel(databaseName, documentID);
            _name = new Lazy<string>(() => Model.Name, LazyThreadSafetyMode.None);
            _imageDigest = new Lazy<string>(() => Model.GetImageDigest(), LazyThreadSafetyMode.None);
            GenerateThumbnail();
        }

        internal bool HasImage()
        {
            return Model.HasImage();
        }

        internal Stream GetImage()
        {
            return Model.GetImage();
        }

        internal void SetImage(Stream image)
        {
            Model.SetImage(image);
        }

        private async Task GenerateThumbnail()
        {
            var service = Mvx.Resolve<IImageService>();
            using(var fullImage = GetImage()) {
                if(fullImage == null) {
                    Thumbnail = service.GenerateSolidColor(44, Color.LightGray, "defaultTaskCell");
                } else {
                    Thumbnail = await service.Square(fullImage, 44, _imageDigest.Value);
                }
            }
        }

        private void Delete()
        {
            try {
                Model.Delete();
            } catch(Exception e) {
                _dialogs.ShowError(e.Message);
            }
        }

        private async Task Edit()
        {
            var result = await _dialogs.PromptAsync(new PromptConfig {
                Title = "Edit Task",
                Text = Name,
                Placeholder = "Task Name"
            });

            if(result.Ok) {
                try {
                    Model.Edit(result.Text);
                } catch(Exception e) {
                    _dialogs.ShowError(e.Message);
                }
            }
        }

        public override bool Equals(object obj)
        {
            var other = obj as TaskCellModel;
            if(other == null) {
                return false;
            }

            return DocumentID.Equals(other.DocumentID) && Name.Equals(other.Name)
                             && String.Equals(_imageDigest.Value, other._imageDigest.Value);
        }

        public override int GetHashCode()
        {
            return DocumentID.GetHashCode() ^ Name.GetHashCode() ^ _imageDigest.Value.GetHashCode();
        }
    }
}

