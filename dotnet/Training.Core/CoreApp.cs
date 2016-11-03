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
using System.Linq;
using System.Threading;

using Acr.UserDialogs;
using Couchbase.Lite;
using Couchbase.Lite.Auth;
using Couchbase.Lite.Store;
using MvvmCross.Core.ViewModels;
using MvvmCross.Platform;
using MvvmCross.Platform.IoC;
using XLabs.Platform.Device;
using XLabs.Platform.Services.Media;

namespace Training.Core
{
    /// <summary>
    /// This is the first location to be reached in the actual shared application
    /// </summary>
    public sealed class CoreApp : MvxApplication
    {
        #region Constants

        /// <summary>
        /// Gets the manager for use in the application
        /// </summary>
        public static readonly Manager AppWideManager = Manager.SharedInstance;
        private static readonly Uri SyncGatewayUrl = new Uri("http://localhost:4984/todo/");

        #endregion

        #region Variables

        private static Replication _pusher;
        private static Replication _puller;
        private static Exception _syncError;
        private static LiveQuery _conflictsLiveQuery;
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
            if(Hint.UsePrebuiltDB) {
                InstallPrebuiltDB();
            }

            var p = Hint.EncryptionEnabled ? password : null;
            var np = Hint.EncryptionEnabled ? newPassword : null;
            OpenDatabase(username, p, np);

            if(Hint.SyncEnabled) {
                StartReplication(username, newPassword ?? password);
            }

            if(Hint.ConflictResolution) {
                StartConflictLiveQuery();
            }
        }

        /// <summary>
        /// Installs a premade database for use in the application
        /// </summary>
        public static void InstallPrebuiltDB()
        {
            // TRAINING: Install pre-built database
            var db = AppWideManager.GetExistingDatabase("todo");
            if(db == null) {
                try {
                    using(var asset = typeof(CoreApp).Assembly.GetManifestResourceStream("todo.zip")) {
                        AppWideManager.ReplaceDatabase("todo", asset, false);
                    }
                } catch(Exception e) {
                    Debug.WriteLine($"Cannot replicate the database: {e}");
                }
            }
        }

        /// <summary>
        /// Opens a given database by name for the session
        /// </summary>
        /// <param name="dbName">The name of the database to open</param>
        /// <param name="key">The key for the database (i.e. password, optional)</param>
        /// <param name="newKey">The updated key for the database (optional)</param>
        public static void OpenDatabase(string dbName, string key, string newKey)
        {
            // TRAINING: Create a database
            var encryptionKey = default(SymmetricKey);
            if(key != null) {
                encryptionKey = new SymmetricKey(key);
            }

            var options = new DatabaseOptions {
                Create = true,
                EncryptionKey = encryptionKey
            };

            Database = AppWideManager.OpenDatabase(dbName, options);
            if(newKey != null) {
                Database.ChangeEncryptionKey(new SymmetricKey(newKey));
            }

            Database.Changed += (sender, args) =>
            {
                if (!args.IsExternal)
                {
                    return;
                }

                var db = (Database)sender;
                foreach(var change in args.Changes)
                {
                    if(!change.IsCurrentRevision)
                    {
                        continue;
                    }

                    var changedDoc = db.GetExistingDocument(change.DocumentId);
                    if (changedDoc == null)
                    {
                        continue;
                    }

                    object docType;
                    if (!changedDoc.Properties.TryGetValue("type", out docType))
                    {
                        continue;
                    }

                    if ((docType as string) != "task-list.user")
                    {
                        continue;
                    }

                    if (changedDoc.UserProperties["username"] as string != db.Name)
                    {
                        continue;
                    }

                    _accessDocuments.Add(changedDoc);
                    changedDoc.Change += HandleAccessChanged;
                }
            };
        }

        /// <summary>
        /// Closes the session database
        /// </summary>
        public static void CloseDatabase()
        {
            StopConflictLiveQuery();
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
        public static void StartReplication(string username, string password = null)
        {
            var authenticator = default(IAuthenticator);
            if(username != null && password != null) {
                authenticator = AuthenticatorFactory.CreateBasicAuthenticator(username, password);
            }

            var db = AppWideManager.GetDatabase(username);
            var pusher = db.CreatePushReplication(SyncGatewayUrl);
            pusher.Continuous = true;
            pusher.Authenticator = authenticator;
            pusher.Changed += HandleReplicationChanged;
            

            var puller = db.CreatePullReplication(SyncGatewayUrl);
            puller.Continuous = true;
            puller.Authenticator = authenticator;
            puller.Changed += HandleReplicationChanged;

            pusher.Start();
            puller.Start();

            _pusher = pusher;
            _puller = puller;
        }

        /// <summary>
        /// Stops the session replication
        /// </summary>
        public static void StopReplication()
        {
            var pusher = Interlocked.Exchange(ref _pusher, null);
            var puller = Interlocked.Exchange(ref _puller, null);

            if(pusher != null) {
                pusher.Changed -= HandleReplicationChanged;
                pusher.Stop();
            }

            if(puller != null) {
                puller.Changed -= HandleReplicationChanged;
                puller.Stop();
            }
        }

        /// <summary>
        /// Starts a live query to watch for conflicts
        /// </summary>
        public static void StartConflictLiveQuery()
        {
            // TRAINING: Detecting when conflicts occur
            _conflictsLiveQuery = Database.CreateAllDocumentsQuery().ToLiveQuery();
            _conflictsLiveQuery.AllDocsMode = AllDocsMode.OnlyConflicts;
            _conflictsLiveQuery.Changed += ResolveConflicts;

            _conflictsLiveQuery.Start();
        }

        /// <summary>
        /// Stops the live query that is watching for conflicts
        /// </summary>
        public static void StopConflictLiveQuery()
        {
            var q = Interlocked.Exchange(ref _conflictsLiveQuery, null);
            q?.Stop();
            q?.Dispose();
        }

        #endregion

        #region Private API

        private static void HandleAccessChanged(object sender, Document.DocumentChangeEventArgs args)
        {
            var changedDoc = Database.GetDocument(args.Change.DocumentId);
            if(!changedDoc.Deleted)
            {
                return;
            }

            _accessDocuments.Remove(changedDoc);
            var deletedRev = changedDoc.LeafRevisions.FirstOrDefault();
            var listId = (JsonUtility.ConvertToNetObject<IDictionary<string, object>>(deletedRev?.UserProperties?["taskList"]))?["id"] as string;
            if(listId == null)
            {
                return;
            }

            var listDoc = Database.GetExistingDocument(listId);
            listDoc?.Purge();
            changedDoc.Purge();
        }

        private static void HandleReplicationChanged(object sender, ReplicationChangeEventArgs args)
        {
            var error = Interlocked.Exchange(ref _syncError, args.LastError);
            if(error != args.LastError) {
                var errorCode = (args.LastError as CouchbaseLiteException)?.CBLStatus?.Code
                    ?? (StatusCode?)(args.LastError as HttpResponseException)?.StatusCode;
                if(errorCode == StatusCode.Unauthorized) {
                    Mvx.Resolve<IUserDialogs>().AlertAsync("Your username or password is not correct.", "Authorization failed");
                }
            }
        }

        private static void ResolveConflicts(object sender, QueryChangeEventArgs e)
        {
            var rows = _conflictsLiveQuery?.Rows;
            if(rows == null) {
                return;
            }

            foreach(var row in rows) {
                var conflicts = row.GetConflictingRevisions().ToArray();
                if(conflicts.Length > 1) {
                    var defaultWinning = conflicts[0];
                    var type = defaultWinning.GetProperty("type") as string ?? "";
                    switch(type) {
                        // TRAINING: Automatic conflict resolution
                        case "task-list":
                        case "task-list.user":
                            var props = defaultWinning.UserProperties;
                            var image = defaultWinning.GetAttachment("image");
                            ResolveConflicts(conflicts, props, image);
                            break;
                        // TRAINING: N-way merge conflict resolution
                        case "task":
                            var merged = NWayMergeConflicts(conflicts);
                            ResolveConflicts(conflicts, merged.Item1, merged.Item2);
                            break;
                        default:
                            break;
                    }
                }
            }
        }

        private static void ResolveConflicts(SavedRevision[] revs, IDictionary<string, object> props, Attachment image)
        {
            Database.RunInTransaction(() =>
            {
                var i = 0;
                foreach(var rev in revs) {
                    var newRev = rev.CreateRevision();
                    if(i == 0) { // Default winning revision
                        newRev.SetUserProperties(props);
                        if(newRev.GetAttachment("image") != image) {
                            newRev.SetAttachment("image", "image/jpg", image?.Content);
                        }
                    } else {
                        newRev.IsDeletion = true;
                    }

                    try {
                        newRev.Save(true);
                    } catch(Exception e) {
                        Debug.WriteLine($"Cannot resolve conflicts with error: {e}");
                        return false;
                    }

                    i += 1;
                }

                return true;
            });
        }

        private static Tuple<IDictionary<string, object>, Attachment> NWayMergeConflicts(SavedRevision[] revs)
        {
            var parent = FindCommonParent(revs);
            if(parent == null) {
                var defaultWinning = revs[0];
                var props = defaultWinning.UserProperties;
                var image = defaultWinning.GetAttachment("image");
                return Tuple.Create(props, image);
            }

            var mergedProps = parent.UserProperties ?? new Dictionary<string, object>();
            var mergedImage = parent.GetAttachment("image");
            var gotTask = false;
            var gotComplete = false;
            var gotImage = false;
            foreach(var rev in revs) {
                var props = rev.UserProperties;
                if(props != null) {
                    if(!gotTask) {
                        var task = Lookup<string>(props, "task");
                        if(task != Lookup<string>(mergedProps, "task")) {
                            mergedProps["task"] = task;
                            gotTask = true;
                        }
                    }

                    if(!gotComplete) {
                        var complete = LookupNullable<bool>(props, "complete");
                        if(complete != LookupNullable<bool>(mergedProps, "complete")) {
                            mergedProps["complete"] = complete.Value;
                            gotComplete = true;
                        }
                    }

                    if(!gotImage) {
                        var attachment = rev.GetAttachment("image");
                        var attachmentDigest = attachment?.Metadata[AttachmentMetadataDictionaryKeys.Digest] as string;
                        if(attachmentDigest != mergedImage?.Metadata?["digest"] as string) {
                            mergedImage = attachment;
                            gotImage = true;
                        }
                    }

                    if(gotTask && gotComplete && gotImage) {
                        break;
                    }
                }
            }

            return Tuple.Create(mergedProps, mergedImage);
        }

        private static Revision FindCommonParent(SavedRevision[] revs)
        {
            var minHistoryCount = 0;
            var histories = new List<SavedRevision[]>();
            foreach(var rev in revs) {
                var history = rev.RevisionHistory?.ToArray() ?? new SavedRevision[0];
                histories.Add(history);
                minHistoryCount = minHistoryCount > 0 ? Math.Min(minHistoryCount, history.Length) : history.Length;
            }

            if(minHistoryCount == 0) {
                return null;
            }

            var commonParent = default(Revision);
            for(int i = 0; i < minHistoryCount; i++) {
                var rev = default(Revision);
                foreach(var history in histories) {
                    if(rev == null) {
                        rev = history[i];
                    } else if(rev.Id != history[i].Id) {
                        rev = null;
                        break;
                    }
                }

                if(rev == null) {
                    break;
                }

                commonParent = rev;
            }

            return commonParent.IsDeletion ? null : commonParent;
        }

        private static T Lookup<T>(IDictionary<string, object> dic, string key) where T : class
        {
            object val;
            if(dic.TryGetValue(key, out val)) {
                return val as T;
            }

            return null;
        }

        private static T? LookupNullable<T>(IDictionary<string, object> dic, string key) where T : struct
        {
            object val;
            if(dic.TryGetValue(key, out val)) {
                return val as T?;
            }

            return null;
        }

        #endregion

        #region Overrides

        public override void Initialize()
        {
            CreatableTypes()
            .EndingWith("ViewModel")
            .AsTypes()
            .RegisterAsDynamic();

            Mvx.RegisterSingleton<IUserDialogs>(() => UserDialogs.Instance);
            Mvx.RegisterType<IMediaPicker>(() => Mvx.Resolve<IDevice>().MediaPicker);
            RegisterAppStart<TaskListsViewModel>();
        }

        #endregion

    }

    /// <summary>
    /// A custom start logic class for MvvmCross
    /// </summary>
    public sealed class CoreAppStart : MvxNavigatingObject, IMvxAppStart
    {

        #region Public API

        /// <summary>
        /// Creates the hint for starting CoreApp, which will control the way the app behaves
        /// </summary>
        /// <returns>The hint object</returns>
        public static CoreAppStartHint CreateHint()
        {
            var retVal = new CoreAppStartHint {
                LoginEnabled = false,
                EncryptionEnabled = false,
                SyncEnabled = false,
                UsePrebuiltDB = false,
                ConflictResolution = false,
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
            Couchbase.Lite.Storage.SQLCipher.Plugin.Register();

            CoreApp.Hint = (CoreAppStartHint)hint;
            if(CoreApp.Hint.LoginEnabled) {
                ShowViewModel<LoginViewModel>();
            } else {
                CoreApp.StartSession(CoreApp.Hint.Username, null, null);
                ShowViewModel<TaskListsViewModel>(new { loginEnabled = false });
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
        /// Gets or sets whether or not to seed the app with a prepopulated database
        /// </summary>
        public bool UsePrebuiltDB { get; set; }

        /// <summary>
        /// Gets or sets whether or not to handle conflict resolution automatically
        /// </summary>
        public bool ConflictResolution { get; set; }

        /// <summary>
        /// Gets or sets the username to use for the session
        /// </summary>
        public string Username { get; set; }
    }
}

