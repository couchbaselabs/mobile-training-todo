using Couchbase.Lite;
using Couchbase.Lite.Query;
using Couchbase.Lite.Sync;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using System.Threading;
using Training.Data;
using Training.Models;
using Xamarin.Forms;

namespace Training
{
    /// <summary>
    /// LOCAL as CCR returning local doc, REMOTE CCR returning remote doc, 
    /// DELELTE CCR returning null, and NONE as no custom conflict resolver.
    /// </summary>
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

        private static readonly Uri SyncGatewayUrl = new Uri("ws://ec2-54-209-32-207.compute-1.amazonaws.com:4984/todo");

        #endregion

        #region Variables

        private static Replicator _replication;
        private static HashSet<Document> _accessDocuments = new HashSet<Document>();

        #endregion

        #region Properties

        /// <summary>
        /// Gets the database for the current session
        /// </summary>
        public static Database Database { get; private set; }

        public static Dictionary<QueryType, IQuery> QueryDictionary { get; private set; }

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
            var qs = new TodoQueries();
            QueryDictionary = qs.QueryDictionary;

            if (Hint.SyncEnabled)
            {
                IConflictResolver resolver = null;
                if (Hint.CCRType != CCR_TYPE.NONE)
                {
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

            Debug.WriteLine($"Custom Conflict Resolver Type = {Hint.CCRType}");
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
        /// <param name="key">The key for the database (i.e. password)</param>
        /// <param name="newKey">The updated key for the database</param>
        public static void OpenDatabase(string dbName, string key, string newKey)
        {
            // TRAINING: Create a database
            Database = new Database(dbName);
            if (newKey != null)
            {
                var config = new DatabaseConfiguration
                {
                    EncryptionKey = new EncryptionKey(key)
                };

                Database = new Database(dbName, config);
            }
            else
            {
                Database = new Database(dbName);
            }

            // Setup data
            DependencyService.Register<TodoDataStore>();
            DependencyService.Register<TasksData>();
            DependencyService.Register<UsersData>();

            if (newKey != null)
            {
                Database.ChangeEncryptionKey(new EncryptionKey(newKey));
            }

            if (Hint.IsDatabaseChangeMonitoring)
            {
                Database.AddChangeListener((sender, args) =>
                {
                    foreach (var id in args.DocumentIDs)
                    {
                        MonitorIfNeeded(id, args.Database.Name);
                    }
                });
            }
        }

        /// <summary>
        /// Closes the session database
        /// </summary>
        public static void CloseDatabase()
        {
            try
            {
                Database.Close();
            }
            catch (Exception e)
            {
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
            var config = new ReplicatorConfiguration(Database, new URLEndpoint(SyncGatewayUrl))
            {
                ReplicatorType = ReplicatorType.PushAndPull,
                Continuous = true
            };

            if (Hint.Heartbeat != null)
            {
                config.Heartbeat = Hint.Heartbeat;
            }

            if (Hint.MaxRetryWaitTime != null)
            {
                config.MaxAttemptsWaitTime = Hint.MaxRetryWaitTime;
            }

            if (Hint.MaxRetries > 0)
            {
                config.MaxAttempts = Hint.MaxRetries;
            }

            if (username != null && password != null)
            {
                config.Authenticator = new BasicAuthenticator(username, password);
            }

            if (resolver != null)
            {
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
            if (userAccessDoc == null || !userAccessDoc.Contains("type"))
            {
                return;
            }

            var docType = userAccessDoc["type"].ToString();
            if (docType != "task-list.user")
            {
                return;
            }

            if (userAccessDoc["username"].ToString() != user)
            {
                return;
            }

            _accessDocuments.Add(userAccessDoc);
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
        /// Gets or sets the username to use for the session
        /// </summary>
        public string Username { get; set; }

        /// <summary>
        /// Gets or sets ccr type
        /// </summary>
        public CCR_TYPE CCRType { get; set; }

        /// <summary>
        /// Gets or sets replicator heartbeat
        /// </summary>
        public TimeSpan? Heartbeat { get; set; }

        /// <summary>
        /// Gets or sets Max retries to reconnect
        /// </summary>
        public int MaxRetries { get; set; }

        /// <summary>
        /// Gets or sets the Max wait time to retry to reconnect
        /// </summary>
        public TimeSpan? MaxRetryWaitTime { get; set; }

        public bool IsDebugging { get; set; } //Deafult set to disable for better performance. Only enable when there are issues.

        public bool IsDatabaseChangeMonitoring { get; set; }
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
