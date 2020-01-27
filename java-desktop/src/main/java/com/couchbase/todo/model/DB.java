package com.couchbase.todo.model;

import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.lite.AbstractReplicator;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.CBLError;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Document;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.LogLevel;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryChangeListener;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.todo.TodoApp;

public class DB {

    private static volatile DB instance;

    private static synchronized void newInstance() { instance = new DB(); }

    private ExecutorService executor = Executors.newSingleThreadExecutor();

    public static synchronized DB get() {
        if (instance == null) { newInstance(); }
        return instance;
    }

    private DB() {
        CouchbaseLite.init();

        if (TodoApp.LOG_ENABLED) {
            Database.log.getConsole().setLevel(LogLevel.VERBOSE);
        }
    }

    public void shutdown() {
        if (isLoggedin.get()) { logout(); }
        executor.shutdown();
    }

    public ExecutorService getExecutor() {
        return executor;
    }

    // -------------------------
    // Login
    // -------------------------

    private volatile String username;

    private final AtomicBoolean isLoggedin = new AtomicBoolean();

    public void login(@NotNull String username, @NotNull String password) {
        if (!isLoggedin.compareAndSet(false, true)) {
            throw new IllegalStateException("Already login, please logout first");
        }

        this.username = username;

        database = openDatabase(username);

        if (TodoApp.SYNC_ENABLED) {
            startReplication(username, password);
        }
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

    @Nullable
    public String getLoggedInUsername() {
        if (username == null) { throw new IllegalStateException("No user logged in."); }
        return username;
    }

    // -------------------------
    // Database
    // -------------------------

    private volatile Database database;

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
        for (int i = 0; i < 5; i++) {
            try {
                db.close();
                return;
            }
            catch (CouchbaseLiteException e) {
                if (e.getCode() == CBLError.Code.BUSY) {
                    try { Thread.sleep(200); }
                    catch (InterruptedException ignore) { }
                    continue;
                }
                reportError(e);
                break;
            }
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

    // -------------------------
    // Document
    // -------------------------

    @NotNull
    public DataSource getDataSource() {
        final Database db = getAndVerifyDb();
        return DataSource.database(db);
    }

    @Nullable
    public Document getDocument(@NotNull String id) {
        return getAndVerifyDb().getDocument(id);
    }

    @Nullable
    public Document saveDocument(@NotNull MutableDocument doc) throws CouchbaseLiteException {
        final Database db = getAndVerifyDb();
        try {
            db.save(doc);
            return db.getDocument(doc.getId());
        }
        catch (CouchbaseLiteException e) {
            reportError(e);
            throw e;
        }
    }

    public void deleteDocument(@NotNull String docId) throws CouchbaseLiteException {
        final Database db = getAndVerifyDb();
        try {
            Document doc = db.getDocument(docId);
            if (doc == null) { return; }
            db.delete(doc);
        }
        catch (CouchbaseLiteException e) {
            reportError(e);
            throw e;
        }
    }

    private void reportError(@NotNull CouchbaseLiteException err) {
        System.err.println("DB error: " + err);
    }

    // -------------------------
    // Query
    // -------------------------

    private final Map<Query, List<ListenerToken>> changeListeners = new HashMap<>();

    @NotNull
    public ListenerToken addChangeListener(@NotNull Query query, @NotNull QueryChangeListener listener) {
        getAndVerifyDb();

        List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) {
            listeners = new ArrayList<>();
            changeListeners.put(query, listeners);
        }

        final ListenerToken token = query.addChangeListener(listener);
        listeners.add(token);

        return token;
    }

    public void removeChangeListeners(@NotNull Query query) {
        final List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        for (ListenerToken token : listeners) { query.removeChangeListener(token); }

        changeListeners.remove(query);
    }

    public void removeAllChangeListeners() {
        List<Query> queries = new ArrayList<>(changeListeners.keySet());
        for (Query query : queries) {
            removeChangeListeners(query);
        }
    }

    // -------------------------
    // Replication
    // -------------------------

    private Replicator replicator;

    private void startReplication(@NotNull String username, @NotNull String password) {
        final Database db = getAndVerifyDb();

        final URI sgUri = getReplicationUri();
        if (sgUri == null) { return; }

        final Endpoint endpoint = new URLEndpoint(sgUri);

        final ReplicatorConfiguration config = new ReplicatorConfiguration(db, endpoint)
            .setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL)
            .setContinuous(true);

        TodoApp.CR_MODE crmode = TodoApp.SYNC_CR_MODE;
        if (crmode == TodoApp.CR_MODE.DEFAULT) {
            config.setConflictResolver(null);
        } else {
            config.setConflictResolver(conflict -> {
                Document local = conflict.getLocalDocument();
                Document remote = conflict.getRemoteDocument();
                if (local == null || remote == null) { return null; }
                if (crmode == TodoApp.CR_MODE.LOCAL) {
                    return local;
                } else if (crmode == TodoApp.CR_MODE.REMOTE) {
                    return remote;
                } else {
                    return null;
                }
            });
        }

        // authentication
        config.setAuthenticator(new BasicAuthenticator(username, password));

        final Replicator replicator = new Replicator(config);

        replicator.addChangeListener(this::changed);

        replicator.start();

        this.replicator = replicator;
    }

    void changed(ReplicatorChange change) {
        final AbstractReplicator.Status status = change.getStatus();
        final CouchbaseLiteException error = status.getError();
        if (error == null) { return; }
        reportError(error);
    }

    @Nullable
    private URI getReplicationUri() {
        try { return URI.create(TodoApp.SYNC_URL).normalize(); }
        catch (IllegalArgumentException ignore) { }

        reportError(new CouchbaseLiteException(
            "Invalid SG URI",
            CBLError.Domain.CBLITE,
            CBLError.Code.INVALID_URL));

        return null;
    }

    private void stopReplication() {
        final Replicator repl = replicator;
        if (repl != null) { repl.stop(); }
    }

}
