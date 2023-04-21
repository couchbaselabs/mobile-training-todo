package com.couchbase.todo.model;

import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CollectionConfiguration;
import com.couchbase.lite.ConsoleLogger;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Document;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryChangeListener;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorStatus;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.todo.Config;
import com.couchbase.todo.Logger;
import com.couchbase.todo.TodoApp;


public class DB {
    public static final String COLLECTION_LISTS = "lists";
    public static final String COLLECTION_TASKS = "tasks";
    public static final String COLLECTION_USERS = "users";

    public static final String KEY_USERNAME = "username";
    public static final String KEY_TASK_LIST = "taskList";
    public static final String KEY_ID = "id";
    public static final String KEY_NAME = "name";
    public static final String KEY_OWNER = "owner";
    public static final String KEY_PARENT_LIST_ID = "taskList.id";

    public static final String KEY_COMPLETE = "complete";
    public static final String KEY_IMAGE = "image";
    public static final String KEY_TASK = "task";
    public static final String KEY_CREATED_AT = "createdAt";
    public static final String KEY_TASK_LIST_ID = "id";
    public static final String KEY_TASK_LIST_OWNER = "owner";

    private static final AtomicReference<DB> INSTANCE = new AtomicReference<>();

    private static final List<String> COLLECTIONS = List.of(COLLECTION_LISTS, COLLECTION_TASKS, COLLECTION_USERS);

    public static DB get() {
        final DB instance = INSTANCE.get();
        if (instance != null) { return instance; }
        INSTANCE.compareAndSet(null, new DB());
        return INSTANCE.get();
    }

    @Nullable
    public static URI getReplicationUri() {
        final String sgwURL = TodoApp.getTodoApp().getConfig().getSgwUri();
        try { return URI.create(sgwURL).normalize(); }
        catch (IllegalArgumentException err) {
            Logger.log("Invalid SG URI: " + sgwURL, err);
        }

        return null;
    }


    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    private final Map<Query, List<ListenerToken>> changeListeners = new HashMap<>();

    private final AtomicBoolean isLoggedin = new AtomicBoolean();

    private volatile Database database;

    private volatile String username;

    private Replicator replicator;

    private DB() {
        CouchbaseLite.init();

        ConsoleLogger log = Database.log.getConsole();
        log.setLevel(LogLevel.DEBUG);
        log.setDomains(LogDomain.ALL_DOMAINS);
        Logger.setLogger(log);
    }

    public ExecutorService getExecutor() { return executor; }

    public void shutdown() {
        if (isLoggedin.get()) { logout(); }
        executor.shutdown();
    }

    // -------------------------
    // Login
    // -------------------------

    public void login(@NotNull String username, @NotNull String password) {
        if (!isLoggedin.compareAndSet(false, true)) {
            throw new IllegalStateException("Already logged in. Please logout first");
        }

        this.username = username;

        database = openDatabase(username);

        if (TodoApp.SYNC_ENABLED) { startReplication(username, password); }
    }

    public void logout() {
        if (!isLoggedin.compareAndSet(true, false)) { return; }

        final Database db = database;
        if (db == null) { return; }

        stopReplication();

        removeAllChangeListeners();

        closeDatabase(db);

        this.username = null;
    }

    // -------------------------
    // Document
    // -------------------------

    @NotNull
    public DataSource.As getDataSource(String collectionName) {
        return DataSource.collection(getAndVerifyCollection(collectionName));
    }

    @Nullable
    public Document getDocument(@NotNull String collectionName, @NotNull String id) {
        try { return getAndVerifyCollection(collectionName).getDocument(id); }
        catch (CouchbaseLiteException e) {
            Logger.log("Failed fetching document: " + id, e);
            throw new RuntimeException(e);
        }
    }

    @Nullable
    public Document saveDocument(@NotNull String collectionName, @NotNull MutableDocument doc)
        throws CouchbaseLiteException {
        final Collection collection = getAndVerifyCollection(collectionName);
        try {
            collection.save(doc);
            return collection.getDocument(doc.getId());
        }
        catch (CouchbaseLiteException e) {
            Logger.log("Failed saving document: " + doc, e);
            throw e;
        }
    }

    public void deleteDocument(@NotNull String collectionName, @NotNull String docId)
        throws CouchbaseLiteException {
        final Collection collection = getAndVerifyCollection(collectionName);
        try {
            Document doc = collection.getDocument(docId);
            if (doc == null) { return; }
            collection.delete(doc);
        }
        catch (CouchbaseLiteException e) {
            Logger.log("Failed deleting document: " + docId, e);
            throw e;
        }
    }

    @Nullable
    public String getLoggedInUsername() {
        if (username == null) { throw new IllegalStateException("No user logged in."); }
        return username;
    }

    // -------------------------
    // Query
    // -------------------------

    public void addChangeListener(@NotNull Query query, @NotNull QueryChangeListener listener) {
        getAndVerifyDb();

        changeListeners.computeIfAbsent(query, k -> new ArrayList<>())
            .add(query.addChangeListener(listener));
    }

    public void removeChangeListeners(@NotNull Query query) {
        final List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        for (ListenerToken token: listeners) { token.remove(); }

        changeListeners.remove(query);
    }

    public void removeAllChangeListeners() {
        List<Query> queries = new ArrayList<>(changeListeners.keySet());
        for (Query query: queries) { removeChangeListeners(query); }
    }

    // -------------------------
    // Replication
    // -------------------------

    void changed(ReplicatorChange change) {
        final ReplicatorStatus status = change.getStatus();
        final CouchbaseLiteException err = status.getError();
        if (err != null) { Logger.log("Replication error: ", err); }
    }

    private void startReplication(@NotNull String username, @NotNull String password) {
        final URI sgUri = getReplicationUri();
        if (sgUri == null) { return; }

        final Config appConfig = TodoApp.getTodoApp().getConfig();
        final ReplicatorConfiguration config = new ReplicatorConfiguration(new URLEndpoint(sgUri))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(true)
            .setMaxAttempts(appConfig.getAttempts())
            .setMaxAttemptWaitTime(appConfig.getAttemptsWaitTime());

        // authentication
        config.setAuthenticator(new BasicAuthenticator(username, password.toCharArray()));

        CollectionConfiguration collConfig = null;
        TodoApp.CR_MODE crmode = appConfig.getCrMode();
        if ((crmode != null) && (crmode != TodoApp.CR_MODE.DEFAULT)) {
            collConfig = new CollectionConfiguration();
            collConfig.setConflictResolver(conflict -> {
                Document local = conflict.getLocalDocument();
                Document remote = conflict.getRemoteDocument();
                if (local == null || remote == null) { return null; }
                return (crmode == TodoApp.CR_MODE.LOCAL) ? local : remote;
            });
        }

        final Set<Collection> collections = new HashSet<>();
        for (String collectionName: COLLECTIONS) {
            collections.add(getAndVerifyCollection(collectionName));
        }

        config.addCollections(collections, collConfig);

        final Replicator replicator = new Replicator(config);

        replicator.addChangeListener(this::changed);

        replicator.start();

        this.replicator = replicator;
    }

    private void stopReplication() {
        final Replicator repl = replicator;
        if (repl != null) { repl.stop(); }
    }

    // -------------------------
    // Database
    // -------------------------

    private @NotNull Database openDatabase(String dbName) {
        try {
            DatabaseConfiguration config = new DatabaseConfiguration();
            config.setDirectory(TodoApp.DB_DIR);
            return new Database(dbName, config);
        }
        catch (CouchbaseLiteException e) {
            throw new IllegalStateException("Cannot open database : " + dbName, e);
        }
    }

    private void closeDatabase(Database db) {
        try { db.close(); }
        catch (CouchbaseLiteException e) {
            Logger.log("Failed closing database", e);
        }
    }


    @NotNull
    private Database getAndVerifyDb() {
        final Database db = database;
        if (db == null) {
            throw new IllegalStateException("Attempt to use the DB before logging in.");
        }
        return db;
    }

    private Collection getAndVerifyCollection(String collectionName) {
        final Database db = getAndVerifyDb();
        try {
            final Collection collection = db.getCollection(collectionName);
            return (collection != null)
                ? collection
                : db.createCollection(collectionName);
        }
        catch (CouchbaseLiteException e) {
            throw new IllegalStateException("Cannot create collection: " + collectionName);
        }
    }
}
