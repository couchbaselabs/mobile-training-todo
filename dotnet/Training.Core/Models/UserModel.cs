//
// UserModel.cs
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
using Couchbase.Lite;
using Robo.Mvvm;
using System;
using Training.Core;

namespace Training.Models
{
    /// <summary>
    /// The model for an entry in the UsersPage table view
    /// </summary>
    public sealed class UserModel : BaseNotify
    {

        #region Variables

        private readonly Document _document;
        private readonly Database _database = CoreApp.Database;

        #endregion

        #region Constructors

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="documentId">The ID of the document containing information about
        /// the user</param>
        public UserModel(string documentId)
        {
            _document = _database.GetDocument(documentId);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Deletes the user
        /// </summary>
        public void Delete()
        {
            try {
                _database.Delete(_document);
            } catch (Exception e) {
                throw new Exception("Failed to delete user", e);
            }
        }

        #endregion
    }
}

