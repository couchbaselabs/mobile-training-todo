//
// TaskModel.cs
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
using Couchbase.Lite;
using Plugin.Media;
using Robo.Mvvm;
using Training.Core;

namespace Training.Models
{
    /// <summary>
    /// The model for an entry in the TasksPage table view
    /// </summary>
    public sealed class TaskModel : BaseNotify
    {

        #region Variables

        private Document _document;
        private Database _database = CoreApp.Database;

        string _docID;

        #endregion

        #region Properties

        /// <summary>
        /// Gets the name of the task (cached)
        /// </summary>
        /// <value>The name.</value>
        public string Name => _name.Value;
        private readonly Lazy<string> _name;

        /// <summary>
        /// Gets or sets whether or not this document is "checked off" (i.e. finished)
        /// </summary>
        /// <value><c>true</c> if the entry is checked off; otherwise, <c>false</c>.</value>
        public bool IsChecked
        {
            get {
                _checked = _document.GetBoolean("complete");
                return _checked;
            }
            set {
                try {
                    using (var mutableDoc = _document.ToMutable())
                    {
                        mutableDoc["complete"].Value = value;
                        _database.Save(mutableDoc);
                    }
                } catch(Exception e) {
                    throw new Exception("Failed to edit task", e);
                }
                _checked = value;
                SetPropertyChanged(ref _checked, value);
            }
        }
        private bool _checked;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentID">The ID of the document containing information about 
        /// this task</param>
        public TaskModel(string documentID)
        {
            _docID = documentID;
            _document = _database.GetDocument(documentID);
            _name = new Lazy<string>(() => _document.GetString("task"), LazyThreadSafetyMode.None);
            _imageDigest = new Lazy<string>(() => {
                var metadata = _document.GetBlob("image")?.Properties;
                if(metadata?.ContainsKey("digest") != true) {
                    return null;
                }
                return _document.GetBlob ("image")?.Digest;
            }, LazyThreadSafetyMode.None);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Gets the digest of the image for this task (cached)
        /// </summary>
        /// <returns>The calculated or cached digest</returns>
        public string GetImageDigest()
        {
            return _imageDigest.Value;
        }
        private Lazy<string> _imageDigest;

        /// <summary>
        /// Indicates whether or not this task has an associated image
        /// </summary>
        /// <returns><c>true</c>, if the task has an image, <c>false</c> otherwise.</returns>
        public bool HasImage()
        {
            return _document.GetBlob("image") != null;
        }

        /// <summary>
        /// Gets the image associated with this task
        /// </summary>
        /// <returns>The image associated with this task</returns>
        public Stream GetImage()
        {
            return _database.GetDocument(_docID).GetBlob("image")?.ContentStream;
        }

        /// <summary>
        /// Sets the image associated with this task
        /// </summary>
        /// <param name="image">The image to associate with the task.</param>
        public void SetImage(byte[] image)
        {
            try {
                using (var mutableDoc = _document.ToMutable()) {
                    if (image == null) {
                        mutableDoc.Remove("image");
                    } else {
                        var blob = new Blob("image/png", image);
                        mutableDoc["image"].Blob = blob;
                    }
                    _database.Save(mutableDoc);
                }
            } catch (Exception e) {
                throw new Exception("Failed to save image", e);
            }
        }

        /// <summary>
        /// Deletes the task
        /// </summary>
        public void Delete()
        {
            try {
                _database.Delete(_document);
            } catch(Exception e) {
                throw new Exception("Failed to delete task", e);
            }
        }

        /// <summary>
        /// Edits the task name
        /// </summary>
        /// <param name="name">The new name for the task.</param>
        public void Edit(string name)
        {
            try {
                using (var mutableDoc = _document.ToMutable())
                {
                    mutableDoc["task"].String = name;
                    _database.Save(mutableDoc);
                }
            } catch(Exception e) {
                throw new Exception("Failed to edit task", e);
            }
        }

        #endregion

    }
}

