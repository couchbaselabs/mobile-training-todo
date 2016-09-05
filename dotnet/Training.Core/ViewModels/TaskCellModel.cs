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
using System.IO;
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

        public ICommand DeleteCommand
        {
            get {
                return new MvxCommand(Delete);
            }
        }

        public string DocumentID { get; }

        /// <summary>
        /// Gets the name of the task
        /// </summary>
        public string Name
        {
            get {
                return Model.Name;
            }
        }

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

                Model.IsChecked = value;
                RaisePropertyChanged(nameof(CheckedImage));
            }
        }

        public string CheckedImage
        {
            get {
                return IsChecked ? "Users.png" : null;
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
            GenerateThumbnail();
        }

        internal async Task SetImage(Stream image)
        {
            Model.SetImage(image);
            await GenerateThumbnail();
        }

        internal Stream GetImage()
        {
            return Model.GetImage();
        }

        private async Task GenerateThumbnail()
        {
            var service = Mvx.Resolve<IImageService>();
            var fullImage = GetImage();
            Thumbnail = await service.Square(fullImage, 44, Model.GetImageDigest());
        }

        private void Delete()
        {
            Model.Delete();
        }

        public override bool Equals(object obj)
        {
            var other = obj as TaskCellModel;
            if(other == null) {
                return false;
            }

            return other.Model.Equals(Model);
        }

        public override int GetHashCode()
        {
            return Model.GetHashCode();
        }
    }
}

