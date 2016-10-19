//
// TaskImageModel.cs
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

using Couchbase.Lite;

namespace Training.Core
{
    /// <summary>
    /// The model for the page that displays a task's saved image
    /// </summary>
    public sealed class TaskImageModel : BaseModel
    {

        #region Variables

        private Document _taskDocument;

        #endregion

        #region Properties

        /// <summary>
        /// The image stored on the task
        /// </summary>
        /// <value>The image.</value>
        public Stream Image
        {
            get {
                return _taskDocument.CurrentRevision.GetAttachment("image")?.ContentStream;
            }
            set {
                _taskDocument.Update(rev =>
                {
                    if(value == null) {
                        rev.RemoveAttachment("image");
                    } else {
                        rev.SetAttachment("image", "image/png", value);
                    }

                    return true;
                });
            }
        }

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentID">The id of the document to read from</param>
        public TaskImageModel(string documentID)
        {
            _taskDocument = CoreApp.Database.GetDocument(documentID);
        }

        #endregion
    }
}

