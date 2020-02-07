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
using Robo.Mvvm;
using Robo.Mvvm.Input;
using Robo.Mvvm.Services;
using Training.Core;
using Training.Models;
using Training.ViewModels;

using Plugin.Media;

namespace Training.ViewModels
{
    /// <summary>
    /// The model for a cell in the list on the Tasks page
    /// </summary>
    public sealed class TaskCellModel : BaseNotify
    {

        #region Variables

        private readonly IUserDialogs _dialogs;
        private readonly ImageChooser _imageChooser;
        private readonly IImageService _imageService;

        #endregion

        #region Properties

        ObservableConcurrentDictionary<string, TaskCellModel> _tasks;
        public ObservableConcurrentDictionary<string, TaskCellModel> Tasks
        {
            get => _tasks;
            set => SetPropertyChanged(ref _tasks, value);
        }

        TaskModel _task;
        public TaskModel Task
        {
            get => _task;
            set => SetPropertyChanged(ref _task, value);
        }

        /// <summary>
        /// Gets the command that handles a delete request
        /// </summary>
        public ICommand DeleteCommand => new Command(() => Delete());

        /// <summary>
        /// Gets the command that handles an edit request
        /// </summary>
        public ICommand EditCommand => new Command(async() => await Edit());

        /// <summary>
        /// Gets the ID of the document being tracked
        /// </summary>
        /// <value>The document identifier.</value>
        public string DocumentID { get; set; }

        /// <summary>
        /// Gets the name of the task
        /// </summary>
        public string Name
        {
            get => _name;
            set => SetPropertyChanged(ref _name, value);
        }
        string _name = "";

        internal bool HasImage
        {
            get { return Task.HasImage(); }
        }

        internal string ImageDigest
        {
            get { return Task.GetImageDigest(); }
        }

//        public Stream Image
//        {
//            get {
//                var img = Task.GetImage();
//Thumbnail = _imageService.Square(img, ImageDigest).Result;
//                return img;
//            }

//        }

        /// <summary>
        /// Gets the thumbnail of the image stored with the task, if it exists
        /// </summary>
        public byte[] Thumbnail
        {
            get => _thumbnail;
            set => SetPropertyChanged(ref _thumbnail, value);
        }
        private byte[] _thumbnail;

        /// <summary>
        /// Gets or sets whether or not the task is checked
        /// </summary>
        public bool IsChecked
        {
            get {
                return _isChecked;
            }
            set {
                _isChecked = value;
                SetPropertyChanged(nameof(CheckedImage));
                SetPropertyChanged(ref _isChecked, value);
            }
        }
        bool _isChecked;

        /// <summary>
        /// Gets the image to use for the checked portion of a table view row
        /// </summary>
        public string CheckedImage => IsChecked ? "Checkmark.png" : null;

        /// <summary>
        /// Gets or sets the command to process an add image request
        /// </summary>
        public ICommand AddImageCommand => new Command(async() => await SelectImage());

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentID">The ID of the document to use</param>
        public TaskCellModel(IUserDialogs dialogs, IImageService imageService,
                             IMediaService mediaPicker, string documentID, ObservableConcurrentDictionary<string, TaskCellModel> tasks)
        {
            DocumentID = documentID;
            Task = new TaskModel(documentID);
            Tasks = tasks;
            _isChecked = Task.IsChecked;
            _dialogs = dialogs;
            _imageService = imageService;
            _imageChooser = new ImageChooser(new ImageChooserConfig
            {
                Dialogs = dialogs,
                MediaPicker = mediaPicker
            });

            using (var s = Task.GetImage())
            {
                Thumbnail = _imageService.Square(s, ImageDigest).Result;
            }
        }

        #endregion

        public void SetCheck()
        {
            try {
                Task.IsChecked = !Task.IsChecked;
            } catch (Exception e) {
                _dialogs.Toast(e.Message);
                return;
            }
            IsChecked = !IsChecked;
        }

        #region Internal API

        private async Task SelectImage()
        {
            await ChooseImage();
            using (var s = Task.GetImage())
            {
                Thumbnail = await _imageService.Square(s, ImageDigest);
            }
        }

        private async Task ChooseImage()
        {

            var result = await _imageChooser.GetPhotoAsync();
            if (result == null) {
                return;
            }

            try {
                Task.SetImage(result);
            } catch (Exception e) {
                _dialogs.Toast(e.Message);
                return;
            }
        }

        #endregion

        #region Private API

        private void Delete()
        {
            try {
                Task.Delete();
            } catch (Exception e) {
                _dialogs.Toast(e.Message);
                return;
            }
            Tasks.Remove(DocumentID);
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
                    Task.Edit(result.Text);
                } catch (Exception e) {
                    _dialogs.Toast(e.Message);
                    return;
                }
            }
            Name = result.Text;
        }

        #endregion

        #region Overrides

        //public override bool Equals(object obj)
        //{
        //    var other = obj as TaskCellModel;
        //    if(other == null) {
        //        return false;
        //    }

        //    return DocumentID.Equals(other.DocumentID) && Name.Equals(other.Name) && IsChecked == other.IsChecked
        //                     && String.Equals(ImageDigest, other.ImageDigest);
        //}

        //public override int GetHashCode()
        //{
        //    var digest = ImageDigest;
        //    var b = DocumentID.GetHashCode() ^ Name.GetHashCode() ^ IsChecked.GetHashCode();
        //    return digest == null ? b : (b ^ digest.GetHashCode());
        //}

        #endregion

    }

    public static class StreamExtensions
    {
        public static byte[] ToByteArray(this Stream stream)
        {
            stream.Position = 0;
            byte[] buffer = new byte[stream.Length];
            for (int totalBytesCopied = 0; totalBytesCopied < stream.Length;)
                totalBytesCopied += stream.Read(buffer, totalBytesCopied, Convert.ToInt32(stream.Length) - totalBytesCopied);
            return buffer;
        }
    }
}

