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
using Couchbase.Lite;

namespace Training.Core
{
    public sealed class TaskModel : BaseModel
    {
        private readonly Document _document;

        public string Name
        {
            get {
                return _document.GetProperty<string>("task");
            }
        }

        public bool IsChecked
        {
            get {
                return _document.GetProperty<bool>("complete");
            }
            set {
                _document.Update(rev =>
                {
                    var existing = (bool)rev.GetProperty("complete");
                    var props = rev.UserProperties;
                    props["complete"] = value;
                    rev.SetUserProperties(props);
                    var saved = existing != value;
                    return saved;
                });
            }
        }

        public TaskModel(string databaseName, string documentID)
        {
            var db = CoreApp.AppWideManager.GetDatabase(databaseName);
            _document = db.GetExistingDocument(documentID);
        }

        public string GetImageDigest()
        {
            return _document.CurrentRevision.GetAttachment("image")?.Metadata?["digest"] as string;
        }


        public Stream GetImage()
        {
            return _document.CurrentRevision.GetAttachment("image")?.ContentStream;
        }

        public void SetImage(Stream image)
        {
            _document.Update(rev =>
            {
                rev.SetAttachment("image", "image/png", image);
                return true;
            });
        }

        public void Delete()
        {
            _document.Delete();
        }

        public override bool Equals(object obj)
        {
            var other = obj as TaskModel;
            if(other == null) {
                return false;
            }

            return _document.Id.Equals(other._document.Id);
        }

        public override int GetHashCode()
        {
            return _document.Id.GetHashCode();
        }
    }
}

