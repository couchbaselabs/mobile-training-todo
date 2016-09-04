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

using Couchbase.Lite;
using MvvmCross.Platform;

namespace Training.Core
{
    /// <summary>
    /// The model for a cell in the list on the Tasks page
    /// </summary>
    public sealed class TaskCellModel : BaseViewModel<TasksModel>
    {
        internal Document Document { get; }

        /// <summary>
        /// Gets the name of the task
        /// </summary>
        public string Name
        {
            get {
                return Document.GetProperty<string>("task");
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
                return Document.GetProperty<bool>("complete");
            }
            set {
                var saved = false;
                Document.Update(rev =>
                {
                    var existing = (bool)rev.GetProperty("complete");
                    var props = rev.UserProperties;
                    props["complete"] = value;
                    rev.SetUserProperties(props);
                    saved = existing != value;
                    return saved;
                });

                if(saved) {
                    RaisePropertyChanged(nameof(CheckedImage));
                }
            }
        }

        /// <summary>
        /// Gets the image to use for the checked area
        /// </summary>
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
        /// <param name="taskDocument">The document to read information from</param>
        public TaskCellModel(Document taskDocument)
        {
            Document = taskDocument;
            GenerateThumbnail();
        }

        internal async Task SetImage(Stream image)
        {
            Document.Update(rev =>
            {
                rev.SetAttachment("image", "image/png", image);
                return true;
            });

            await GenerateThumbnail();
        }

        internal Stream GetImage()
        {
            return Document.CurrentRevision.GetAttachment("image")?.ContentStream;
        }

        private async Task GenerateThumbnail()
        {
            var service = Mvx.Resolve<IImageService>();
            var att = Document.CurrentRevision.GetAttachment("image");
            Thumbnail = await service.Square(att?.ContentStream, 44, att?.Metadata?["digest"] as string);
        }
    }
}

