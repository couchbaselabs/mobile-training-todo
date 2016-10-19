//
// LoginModel.cs
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

namespace Training.Core
{
    
    /// <summary>
    /// Model logic for the login page
    /// </summary>
    public sealed class LoginModel : BaseModel
    {

        #region Public API

        /// <summary>
        /// Checks to see if a username is valid (i.e. can be used as a database name)
        /// </summary>
        /// <param name="username">The username to check</param>
        /// <returns><c>true</c> if the username is valid, <c>false</c> otherwise</returns>
        public static bool IsValidUsername(string username)
        {
            return Manager.IsValidDatabaseName(username);
        }

        /// <summary>
        /// Deletes a database by name (used in migration logic)
        /// </summary>
        /// <param name="dbName">The name of the database to delete</param>
        public void DeleteDatabase(string dbName)
        {
            CoreApp.AppWideManager.DeleteDatabase(dbName);
        }

        #endregion
    }
}
