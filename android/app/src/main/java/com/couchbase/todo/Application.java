package com.couchbase.todo;

import android.content.Intent;
import android.os.Handler;
import android.os.StrictMode;
import android.util.Log;
import android.widget.Toast;

import com.couchbase.lite.Attachment;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseOptions;
import com.couchbase.lite.Document;
import com.couchbase.lite.DocumentChange;
import com.couchbase.lite.LiveQuery;
import com.couchbase.lite.Manager;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryEnumerator;
import com.couchbase.lite.QueryRow;
import com.couchbase.lite.SavedRevision;
import com.couchbase.lite.TransactionalTask;
import com.couchbase.lite.UnsavedRevision;
import com.couchbase.lite.android.AndroidContext;
import com.couchbase.lite.auth.Authenticator;
import com.couchbase.lite.auth.AuthenticatorFactory;
import com.couchbase.lite.replicator.Replication;
import com.couchbase.lite.util.ZipUtils;
import com.facebook.stetho.Stetho;
import com.robotpajamas.stetho.couchbase.CouchbaseInspectorModulesProvider;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static android.content.Intent.FLAG_ACTIVITY_NEW_TASK;
import static java.lang.Math.min;

public class Application extends android.app.Application {
    public static final String TAG = "Todo";
    public static final String LOGIN_FLOW_ENABLED = "login_flow_enabled";

    private Boolean mLoginFlowEnabled = false;
    private Boolean mEncryptionEnabled = false;
    private Boolean mSyncEnabled = false;
    private String mSyncGatewayUrl = "http://10.0.2.2:4984/todo/";
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

        StrictMode.VmPolicy.Builder builder = new StrictMode.VmPolicy.Builder();
        StrictMode.setVmPolicy(builder.build());

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
        startConflictLiveQuery();
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

                    String docType = (String) changedDoc.getProperty("type");
                    if(!docType.equals("task-list.user")) {
                        continue;
                    }

                    String username = (String) changedDoc.getProperty("username");
                    if(!username.equals(getUsername())) {
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
        // TODO: stop conflicts live query
        database.close();
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
        intent.putExtra(LOGIN_FLOW_ENABLED, mLoginFlowEnabled);
        startActivity(intent);
    }

    public void login(String username, String password) {
        mUsername = username;
        startSession(username, password, null);
    }

    public void logout() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                stopReplication();
                closeDatabase();
                login();
            }
        });
    }

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

        ReplicationChangeListener changeListener = new ReplicationChangeListener(this);

        pusher = database.createPushReplication(url);
        pusher.setContinuous(true); // Runs forever in the background
        pusher.addChangeListener(changeListener);

        puller = database.createPullReplication(url);
        puller.setContinuous(true); // Runs forever in the background
        puller.addChangeListener(changeListener);

        if (mLoginFlowEnabled) {
            Authenticator authenticator = AuthenticatorFactory.createBasicAuthenticator(username, password);
            pusher.setAuthenticator(authenticator);
            puller.setAuthenticator(authenticator);
        }

        pusher.start();
        puller.start();
    }

    private void stopReplication() {
        if (!mSyncEnabled) {
            return;
        }

        pusher.stop();
        puller.stop();
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
                String msg = String.format("%s",
                        errorMessage);
                Toast.makeText(getApplicationContext(), msg, Toast.LENGTH_LONG).show();
            }
        });
    }

    private void runOnUiThread(Runnable runnable) {
        Handler mainHandler = new Handler(getApplicationContext().getMainLooper());
        mainHandler.post(runnable);
    }

    private void startConflictLiveQuery() {
        if (!mConflictResolution) {
            return;
        }

        LiveQuery conflictsLiveQuery = database.createAllDocumentsQuery().toLiveQuery();
        conflictsLiveQuery.setAllDocsMode(Query.AllDocsMode.ONLY_CONFLICTS);
        conflictsLiveQuery.addChangeListener(new LiveQuery.ChangeListener() {
            @Override
            public void changed(LiveQuery.ChangeEvent event) {
                resolveConflicts(event.getRows());
            }
        });
        conflictsLiveQuery.start();
    }

    private void resolveConflicts(QueryEnumerator rows) {
        for (QueryRow row : rows) {
            List<SavedRevision> revs = row.getConflictingRevisions();
            if (revs.size() > 1) {
                SavedRevision defaultWinning = revs.get(0);
                String type = (String) defaultWinning.getProperty("type");
                switch (type) {
                    // TRAINING: Automatic conflict resolution
                    case "task-list":
                    case "task-list.user":
                        Map<String, Object> props = defaultWinning.getUserProperties();
                        Attachment image = defaultWinning.getAttachment("image");
                        resolveConflicts(revs, props, image);
                        break;
                    // TRAINING: N-way merge conflict resolution
                    case "task":
                        List<Object> mergedPropsAndImage = nWayMergeConflicts(revs);
                        resolveConflicts(revs, (Map<String, Object>) mergedPropsAndImage.get(0), (Attachment) mergedPropsAndImage.get(1));
                        break;
                }
            }
        }
    }

    private void resolveConflicts(final List<SavedRevision> revs, final Map<String, Object> desiredProps, final Attachment desiredImage) {
        database.runInTransaction(new TransactionalTask() {
            @Override
            public boolean run() {
                int i = 0;
                for (SavedRevision rev : revs) {
                    UnsavedRevision newRev = rev.createRevision(); // Create new revision
                    if (i == 0) { // That's the current/winning revision
                        newRev.setUserProperties(desiredProps);
                        if (desiredImage != null) {
                            try {
                                newRev.setAttachment("image", "image/jpg", desiredImage.getContent());
                            } catch (CouchbaseLiteException e) {
                                e.printStackTrace();
                            }
                        }
                    } else { // That's a conflicting revision, delete it
                        newRev.setIsDeletion(true);
                    }

                    try {
                        newRev.save(true); // Persist the new revision
                    } catch (CouchbaseLiteException e) {
                        e.printStackTrace();
                        return false;
                    }
                    i++;
                }
                return true;
            }
        });
    }

    private List<Object> nWayMergeConflicts(List<SavedRevision> revs) {
        SavedRevision parent = findCommonParent(revs);
        if (parent == null) {
            SavedRevision defaultWinning = revs.get(0);
            Map<String, Object> props = defaultWinning.getUserProperties();
            Attachment image = defaultWinning.getAttachment("image");
            List<Object> propsAndImage = new ArrayList<>();
            propsAndImage.add(props);
            propsAndImage.add(image);
            return propsAndImage;
        }

        Map<String, Object> mergedProps = parent.getUserProperties();
        if (mergedProps == null) mergedProps = new HashMap<>();
        Attachment mergedImage = parent.getAttachment("image");
        boolean gotTask = false;
        boolean gotComplete = false;
        boolean gotImage = false;
        for (SavedRevision rev : revs) {
            Map<String, Object> props = rev.getUserProperties();
            if (props != null) {
                if (!gotTask) {
                    String task = (String) props.get("task");
                    if (!task.equals(mergedProps.get("task"))) {
                        mergedProps.put("task", task);
                        gotTask = true;
                    }
                }

                if (!gotComplete) {
                    boolean complete = (boolean) props.get("complete");
                    if (complete != (boolean) mergedProps.get("complete")) {
                        mergedProps.put("complete", complete);
                        gotComplete = true;
                    }
                }
            }

            if (!gotImage) {
//                Attachment attachment = rev.getAttachment("image");
//                String attachmentDigest = (String) attachment.getMetadata().get("digest");
//                if (attachmentDigest != mergedImage.getMetadata().get("digest")) {
//                    mergedImage = attachment;
//                    gotImage = true;
//                }
                gotImage = true;
            }

            if (gotTask && gotComplete && gotImage) {
                break;
            }
        }

        List<Object> propsAndImage = new ArrayList<>();
        propsAndImage.add(mergedProps);
        propsAndImage.add(mergedImage);
        return propsAndImage;
    }

    private SavedRevision findCommonParent(List<SavedRevision> revisions) {
        int minHistoryCount = 0;
        ArrayList<List<SavedRevision>> histories = new ArrayList<>();
        for (SavedRevision rev : revisions) {
            List<SavedRevision> history = null;
            try {
                history = rev.getRevisionHistory();
            } catch (CouchbaseLiteException e) {
                e.printStackTrace();
            }
            if (history == null) history = new ArrayList<>();
            histories.add(history);
            if (minHistoryCount > 0) {
                minHistoryCount = min(minHistoryCount, history.size());
            } else {
                minHistoryCount = history.size();
            }
        }

        if (minHistoryCount == 0) {
            return null;
        }

        SavedRevision commonParent = null;
        for (int i = 0; i < minHistoryCount; i++) {
            SavedRevision rev = null;
            for (List<SavedRevision> history : histories) {
                if (rev == null) {
                    rev = history.get(i);
                } else if (!rev.getId().equals(history.get(i).getId())) {
                    rev = null;
                    break;
                }
            }
            if (rev == null) {
                break;
            }
            commonParent = rev;
        }

        if (commonParent.isDeletion()) {
            commonParent = null;
        }
        return commonParent;
    }

}
