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
using System.Linq;
using System.Threading;
using Couchbase.Lite;

namespace Training.Core
{
    public sealed class TaskModel : BaseModel
    {
        private readonly Document _document;

        public string Name
        {
            get {
                return _name.Value;
            }
        }
        private Lazy<string> _name;

        public bool IsChecked
        {
            get {
                return _document.GetProperty<bool>("complete");
            }
            set {
                try {
                    _document.Update(rev =>
                    {
                        var existing = (bool)rev.GetProperty("complete");
                        var props = rev.UserProperties;
                        props["complete"] = value;
                        rev.SetUserProperties(props);
                        var saved = existing != value;
                        return saved;
                    });
                } catch(Exception e) {
                    throw new ApplicationException("Failed to edit task", e);
                }
            }
        }

        public TaskModel(string databaseName, string documentID)
        {
            var db = CoreApp.AppWideManager.GetDatabase(databaseName);
            _document = db.GetExistingDocument(documentID);
            _name = new Lazy<string>(() => _document.GetProperty<string>("task"), LazyThreadSafetyMode.None);
            _imageDigest = new Lazy<string>(() => _document.CurrentRevision.GetAttachment("image")?.Metadata?["digest"] as string, LazyThreadSafetyMode.None);
        }

        public string GetImageDigest()
        {
            return _imageDigest.Value;
        }
        private Lazy<string> _imageDigest;

        public bool HasImage()
        {
            return _document.CurrentRevision.AttachmentNames.Contains("image");
        }

        public Stream GetImage()
        {
            return _document.CurrentRevision.GetAttachment("image")?.ContentStream;
        }

        public void SetImage(Stream image)
        {
            try {
                _document.Update(rev =>
                {
                    if(image == null) {
                        rev.RemoveAttachment("image");
                    } else {
                        rev.SetAttachment("image", "image/png", image);
                    }

                    return true;
                });
            } catch(Exception e) {
                throw new ApplicationException("Failed to save image", e);
            }
        }

        public void Delete()
        {
            try {
                _document.Delete();
            } catch(Exception e) {
                throw new ApplicationException("Failed to delete task", e);
            }
        }

        public void Edit(string name)
        {
            try {
                _document.Update(rev =>
                {
                    var props = rev.UserProperties;
                    var oldName = props["task"];
                    props["task"] = name;
                    rev.SetUserProperties(props);
                    return !String.Equals(oldName, name);
                });
            } catch(Exception e) {
                throw new ApplicationException("Failed to edit task", e);
            }
        }
    }
}

