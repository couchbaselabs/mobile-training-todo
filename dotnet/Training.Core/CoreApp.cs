//
// CoreApp.cs
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
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using Couchbase.Lite;
using Couchbase.Lite.Sync;

namespace Training.Core
{
    public enum CCR_TYPE
    {
        LOCAL, REMOTE, DELETE, NONE
    }

    /// <summary>
    /// This is the first location to be reached in the actual shared application
    /// </summary>
    public sealed class CoreApp
    {
        #region Constants

        //private static readonly Uri SyncGatewayUrl = new Uri("ws://ec2-3-85-244-123.compute-1.amazonaws.com:4984/todo");
        private static readonly Uri SyncGatewayUrl = new Uri("ws://ec2-54-197-194-172.compute-1.amazonaws.com:4984/todo");

        #endregion

        #region Variables

        private static Replicator _replication;
        private static Exception _syncError;
        private static HashSet<Document> _accessDocuments = new HashSet<Document>();

        #endregion

        #region Properties

        /// <summary>
        /// Gets the database for the current session
        /// </summary>
        public static Database Database { get; private set; }

        internal static CoreAppStartHint Hint { get; set; }

        #endregion

        #region Public API

        /// <summary>
        /// Starts a new session for a user
        /// </summary>
        /// <param name="username">The username to use for the session</param>
        /// <param name="password">The password to use for the session (optional)</param>
        /// <param name="newPassword">The new password for the database (optional)</param>
        public static void StartSession(string username, string password, string newPassword)
        {
            Couchbase.Lite.Database.Log.Console.Level = Couchbase.Lite.Logging.LogLevel.Debug;
            //if(Hint.UsePrebuiltDB) {
            //    InstallPrebuiltDB();
            //}

            var p = Hint.EncryptionEnabled ? password : null;
            var np = Hint.EncryptionEnabled ? newPassword : null;
            OpenDatabase(username, p, np);

            if(Hint.SyncEnabled) {
                IConflictResolver resolver = null;
                if (Hint.CCREnabled == true) {
                    resolver = new TestConflictResolver((conflict) =>
                    {
                        if (Hint.CCRType == CCR_TYPE.REMOTE)
                            return conflict.RemoteDocument;
                        else if (Hint.CCRType == CCR_TYPE.LOCAL)
                            return conflict.LocalDocument;
                        else
                            return null;
                    });
                }
                StartReplication(username, newPassword ?? password, resolver);
            }

            Debug.WriteLine($"Custom Conflict Resolver: Enabled = {Hint.CCREnabled}; Type = {Hint.CCRType}");
        }

        public static void EndSession()
        {
            StopReplication();
            CloseDatabase();
        }

        /// <summary>
        /// Installs a premade database for use in the application
        /// </summary>
        //public static void InstallPrebuiltDB()
        //{
        //    // TRAINING: Install pre-built database
        //    var db = AppWideManager.GetExistingDatabase("todo");
        //    if(db == null) {
        //        try {
        //            using(var asset = typeof(CoreApp).Assembly.GetManifestResourceStream("todo.zip")) {
        //                AppWideManager.ReplaceDatabase("todo", asset, false);
        //            }
        //        } catch(Exception e) {
        //            Debug.WriteLine($"Cannot replicate the database: {e}");
        //        }
        //    }
        //}

        /// <summary>
        /// Opens a given database by name for the session
        /// </summary>
        /// <param name="dbName">The name of the database to open</param>
        /// <param name="key">The key for the database (i.e. password, optional)</param>
        /// <param name="newKey">The updated key for the database (optional)</param>
        public static void OpenDatabase(string dbName, string key, string newKey)
        {
            // TRAINING: Create a database

            Database =new Database(dbName);
            if (newKey != null) {
                var config = new DatabaseConfiguration
                {
                    EncryptionKey = new EncryptionKey(key)
                };
                Database = new Database(dbName, config);
            } else {
                Database = new Database(dbName);
            }

            if (newKey != null) {
                Database.ChangeEncryptionKey(new EncryptionKey(newKey));
            }

            Database.AddChangeListener((sender, args) =>
            {
                foreach (var id in args.DocumentIDs) {
                    MonitorIfNeeded(id, args.Database.Name);
                }
            });
        }

        /// <summary>
        /// Closes the session database
        /// </summary>
        public static void CloseDatabase()
        {
            try {
                Database.Close();
            } catch(Exception e) {
                Debug.WriteLine($"Failed to close DB {e}");
            }
        }

        /// <summary>
        /// Starts a replication for the session
        /// </summary>
        /// <param name="username">The username to use for the replication</param>
        /// <param name="password">The password to use for replication auth (optional)</param>
        public static void StartReplication(string username, string password, IConflictResolver resolver = null)
        {
            var config = new ReplicatorConfiguration(Database, new URLEndpoint(SyncGatewayUrl)) {
                ReplicatorType = ReplicatorType.PushAndPull,
                Continuous = true
            };

            if (username != null && password != null) {
                config.Authenticator = new BasicAuthenticator(username, password);
            }

            if(resolver != null) {
                config.ConflictResolver = resolver;
            }

            _replication = new Replicator(config);
            _replication.AddChangeListener((sender, args) =>
            {
                Console.WriteLine(args.Status.Activity);
            });
            _replication.Start();
        }

        /// <summary>
        /// Stops the session replication
        /// </summary>
        public static void StopReplication()
        {
            var old = Interlocked.Exchange(ref _replication, null);
            old?.Stop();
        }

        #endregion

        #region Private API

        private static void MonitorIfNeeded(string docID, string user)
        {
            var userAccessDoc = Database.GetDocument(docID);
            if(userAccessDoc == null || !userAccessDoc.Contains("type")) {
                return;
            }

            var docType = userAccessDoc["type"].ToString();
            if(docType != "task-list.user") {
                return;
            }

            if(userAccessDoc["username"].ToString() != user) {
                return;
            }

            _accessDocuments.Add(userAccessDoc);
        }

        #endregion

    }

    /// <summary>
    /// A custom start logic class for MvvmCross
    /// </summary>
    public sealed class CoreAppStart
    {

        #region Public API

        /// <summary>
        /// Creates the hint for starting CoreApp, which will control the way the app behaves
        /// </summary>
        /// <returns>The hint object</returns>
        public static CoreAppStartHint CreateHint()
        {
            var retVal = new CoreAppStartHint {
                LoginEnabled = true,
                EncryptionEnabled = false,
                SyncEnabled = true,
                CCREnabled = false,
                CCRType = CCR_TYPE.NONE,
                UsePrebuiltDB = false,
                Username = "todo"
            };

            return retVal;
        }

        /// <summary>
        /// Starts the app
        /// </summary>
        /// <param name="hint">The hint object to use (See <see cref="CoreAppStart"/>) </param>
        public void Start(object hint = null)
        {
            CoreApp.Hint = (CoreAppStartHint)hint;
            if (!CoreApp.Hint.LoginEnabled) {
                CoreApp.StartSession(CoreApp.Hint.Username, null, null);
            }
        }

        #endregion

    }

    /// <summary>
    /// The hints for how the application should function
    /// </summary>
    public sealed class CoreAppStartHint
    {
        /// <summary>
        /// Gets or sets whether or not to use login functionality
        /// </summary>
        public bool LoginEnabled { get; set; }

        /// <summary>
        /// Gets or sets whether or not to use encryption on the local DB files
        /// </summary>
        public bool EncryptionEnabled { get; set; }

        /// <summary>
        /// Gets or sets whether or not to use sync
        /// </summary>
        public bool SyncEnabled { get; set; }

        /// <summary>
        /// Gets or sets whether or not to use ccr
        /// </summary>
        public bool CCREnabled { get; set; }

        /// <summary>
        /// Gets or sets ccr type
        /// </summary>
        public CCR_TYPE CCRType { get; set; }

        /// <summary>
        /// Gets or sets whether or not to seed the app with a prepopulated database
        /// </summary>
        public bool UsePrebuiltDB { get; set; }

        /// <summary>
        /// Gets or sets the username to use for the session
        /// </summary>
        public string Username { get; set; }
    }

    public class TestConflictResolver : IConflictResolver
    {
        Func<Conflict, Document> ResolveFunc { get; set; }

        public TestConflictResolver(Func<Conflict, Document> resolveFunc)
        {
            ResolveFunc = resolveFunc;
        }

        public Document Resolve(Conflict conflict)
        {
            return ResolveFunc(conflict);
        }
    }
}

