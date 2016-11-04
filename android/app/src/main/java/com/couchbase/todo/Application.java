package com.couchbase.todo;

import android.app.ListActivity;
import android.content.Intent;
import android.os.Handler;
import android.util.Log;
import android.widget.Toast;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseOptions;
import com.couchbase.lite.Manager;
import com.couchbase.lite.android.AndroidContext;
import com.couchbase.lite.auth.Authenticator;
import com.couchbase.lite.auth.AuthenticatorFactory;
import com.couchbase.lite.auth.LoginAuthorizer;
import com.couchbase.lite.listener.Credentials;
import com.couchbase.lite.listener.LiteListener;
import com.couchbase.lite.replicator.Replication;
import com.couchbase.lite.util.ZipUtils;
import com.facebook.stetho.Stetho;
import com.robotpajamas.stetho.couchbase.CouchbaseInspectorModulesProvider;

import java.io.IOException;
import java.io.Serializable;
import java.net.MalformedURLException;
import java.net.URL;

import static android.R.attr.value;
import static android.content.Intent.FLAG_ACTIVITY_NEW_TASK;

public class Application extends android.app.Application {
    public static final String TAG = "Todo";

    private Boolean mLoginFlowEnabled = false;
    private Boolean mEncryptionEnabled = false;
    private Boolean mSyncEnabled = false;
    private String mSyncGatewayUrl = "http://localhost:4984/todo/";
    private Boolean mLoggingEnabled = false;
    private Boolean mUsePrebuiltDb = false;
    private Boolean mConflictResolution = false;

    public Database getDatabase() {
        return database;
    }

    private Manager manager;
    private Database database;
    private Replication pusher;
    private Replication puller;
    private ArrayList<Document> accessDocuments = new ArrayList<Document>();

    private String mUsername;

    @Override
    public void onCreate() {
        super.onCreate();

        if (BuildConfig.DEBUG) {
            Stetho.initialize(
                    Stetho.newInitializerBuilder(this)
                            .enableDumpapp(Stetho.defaultDumperPluginsProvider(this))
                            .enableWebKitInspector(new CouchbaseInspectorModulesProvider(this))
                            .build());
        }

        if (mLoginFlowEnabled) {
            login();
        } else {
            startSession("todo", null, null);
        }

        try {
            manager = new Manager(new AndroidContext(getApplicationContext()), Manager.DEFAULT_OPTIONS);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // Logging

    private void enableLogging() {
        Manager.enableLogging(TAG, Log.VERBOSE);
        Manager.enableLogging(com.couchbase.lite.util.Log.TAG, Log.VERBOSE);
        Manager.enableLogging(com.couchbase.lite.util.Log.TAG_SYNC_ASYNC_TASK, Log.VERBOSE);
        Manager.enableLogging(com.couchbase.lite.util.Log.TAG_SYNC, Log.VERBOSE);
        Manager.enableLogging(com.couchbase.lite.util.Log.TAG_QUERY, Log.VERBOSE);
        Manager.enableLogging(com.couchbase.lite.util.Log.TAG_VIEW, Log.VERBOSE);
        Manager.enableLogging(com.couchbase.lite.util.Log.TAG_DATABASE, Log.VERBOSE);
    }

    // Session

    private void startSession(String username, String password, String newPassword) {
        enableLogging();
        installPrebuiltDb();
        openDatabase(username, password, newPassword);
        mUsername = username;
        startReplication(username, password);
        showApp();
    }

    private void installPrebuiltDb() {
        if (!mUsePrebuiltDb) {
            return;
        }

        try {
            manager = new Manager(new AndroidContext(getApplicationContext()), Manager.DEFAULT_OPTIONS);
        } catch (IOException e) {
            e.printStackTrace();
        }
        try {
            database = manager.getExistingDatabase("todo");
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        if (database == null) {
            try {
                ZipUtils.unzip(getAssets().open("todo.zip"), manager.getContext().getFilesDir());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private void openDatabase(String username, String key, String newKey) {
        String dbname = username;
        DatabaseOptions options = new DatabaseOptions();
        options.setCreate(true);

        if (mEncryptionEnabled) {
            options.setEncryptionKey(key);
        }

        Manager manager = null;
        try {
            manager = new Manager(new AndroidContext(getApplicationContext()), Manager.DEFAULT_OPTIONS);
        } catch (IOException e) {
            e.printStackTrace();
        }
        try {
            database = manager.openDatabase(dbname, options);
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        if (newKey != null) {
            try {
                database.changeEncryptionKey(newKey);
            } catch (CouchbaseLiteException e) {
                e.printStackTrace();
            }
        }

        database.addChangeListener(new Database.ChangeListener() {
            @Override
            public void changed(Database.ChangeEvent event) {
                if(!event.isExternal()) {
                    return;
                }

                for(final DocumentChange change : event.getChanges()) {
                    if(!change.isCurrentRevision()) {
                        continue;
                    }

                    Document changedDoc = database.getExistingDocument(change.getDocumentId());
                    if(changedDoc == null) {
                        return;
                    }

                    Object docType = changedDoc.getProperty("type");
                    if(docType == null || !String.class.isInstance(docType)) {
                        continue;
                    }

                    if((String)docType != "task-list.user") {
                        continue;
                    }

                    Object username = changedDoc.getProperty("username");
                    if(username == null || !String.class.isInstance(username)) {
                        continue;
                    }

                    accessDocuments.add(changedDoc);
                    changedDoc.addChangeListener(new Document.ChangeListener() {
                        @Override
                        public void changed(Document.ChangeEvent event) {
                            Document changedDoc = database.getDocument(event.getChange().getDocumentId());
                            if (!changedDoc.isDeleted()) {
                                return;
                            }

                            try {
                                SavedRevision deletedRev = changedDoc.getLeafRevisions().get(0);
                                String listId = (String) ((HashMap<String, Object>) deletedRev.getProperty("taskList")).get("id");
                                Document listDoc = database.getExistingDocument(listId);
                                accessDocuments.remove(changedDoc);
                                listDoc.purge();
                                changedDoc.purge();
                            } catch (CouchbaseLiteException e) {
                                Log.e(TAG, "Failed to get deleted rev in document change listener");
                            }
                        }
                    });
                }
            }
        });
    }

    private void closeDatabase() {
        // stop live query
        // close the database
    }

    // Login

    private void login() {
        Intent intent = new Intent();
        intent.setFlags(FLAG_ACTIVITY_NEW_TASK);
        intent.setClass(getApplicationContext(), LoginActivity.class);
        startActivity(intent);
    }

    private void showApp() {
        Intent intent = new Intent();
        intent.setFlags(FLAG_ACTIVITY_NEW_TASK);
        intent.setClass(getApplicationContext(), ListsActivity.class);
        startActivity(intent);
    }

    public void login(String username, String password) {
        mUsername = username;
        startSession(username, password, null);
    }

    private void logout() {

    }

    // LoginActivity

    // Replication

    private void startReplication(String username, String password) {
        if (!mSyncEnabled) {
            return;
        }

        URL url = null;
        try {
            url = new URL(mSyncGatewayUrl);
        } catch (MalformedURLException e) {
            e.printStackTrace();
        }

        pusher = database.createPushReplication(url);
        pusher.setContinuous(true);

        puller = database.createPullReplication(url);
        puller.setContinuous(true);

        if (mLoginFlowEnabled) {
            Authenticator authenticator = AuthenticatorFactory.createBasicAuthenticator(username, password);
            pusher.setAuthenticator(authenticator);
            puller.setAuthenticator(authenticator);
        }

        pusher.start();
        puller.start();
    }


    public String getUsername() {
        return mUsername;
    }

    public void setUsername(String mUsername) {
        this.mUsername = mUsername;
    }

    public void showErrorMessage(final String errorMessage, final Throwable throwable) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                android.util.Log.e(TAG, errorMessage, throwable);
                String msg = String.format("%s: %s",
                        errorMessage, throwable != null ? throwable : "");
                Toast.makeText(getApplicationContext(), msg, Toast.LENGTH_LONG).show();
            }
        });
    }

    private void runOnUiThread(Runnable runnable) {
        Handler mainHandler = new Handler(getApplicationContext().getMainLooper());
        mainHandler.post(runnable);
    }
}
