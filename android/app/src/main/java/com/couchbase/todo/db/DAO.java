//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
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
package com.couchbase.todo.db;

import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import androidx.annotation.WorkerThread;

import java.net.URI;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;

import com.couchbase.lite.AbstractReplicator;
import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.CBLError;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Document;
import com.couchbase.lite.Endpoint;
import com.couchbase.lite.From;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.QueryChangeListener;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.todo.config.Config;


public final class DAO {
    private static final String TAG = "DAO";

    public interface DAOListener {
        void onError(CouchbaseLiteException err);

        void onNewState(AbstractReplicator.ActivityLevel state);
    }

    private static class LogoutTask extends AsyncTask<Database, Void, Void> {
        private final boolean deleting;

        public LogoutTask(boolean deleting) { this.deleting = deleting; }

        @Override
        protected Void doInBackground(Database... dbs) {
            final DAO dao = DAO.get();
            for (Database db: dbs) {
                if (deleting) { dao.deleteDatabase(db); }
                else { dao.closeDatabase(db); }
            }
            return null;
        }
    }

    private static volatile DAO instance;

    private static synchronized void newInstance() { instance = new DAO(); }

    @NonNull
    public static synchronized DAO get() {
        if (instance == null) { newInstance(); }
        return instance;
    }


    private final Map<Query, List<ListenerToken>> changeListeners = new HashMap<>();

    private List<CouchbaseLiteException> errors = new ArrayList<>();
    private DAOListener listener;

    private final Handler mainHandler;

    private final AtomicBoolean open = new AtomicBoolean();

    private volatile Database database;
    private volatile String username;

    private Replicator replicator;
    private AbstractReplicator.ActivityLevel replicatorState;

    // Called from the UI thread only once, in ToDo.onCreate()
    private DAO() {
        mainHandler = new Handler(Looper.getMainLooper());

        if (!Config.get().isLoginRequired()) {
            // open a default database
            open.set(true);
            username = Config.get().getDbName();
            database = openDatabase(username);
        }
    }

    public void registerListener(@Nullable DAOListener listener) {
        final List<CouchbaseLiteException> errors;
        synchronized (this) {
            if (Objects.equals(this.listener, listener)) { return; }

            this.listener = listener;
            if (this.listener == null) { return; }

            errors = this.errors;
            this.errors = new ArrayList<>();
        }

        for (CouchbaseLiteException err: errors) { deliverError(listener, err); }
        deliverNewState(listener, replicatorState);
    }

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    @UiThread
    @NonNull
    public ListenerToken addChangeListener(
        @NonNull Query query,
        @NonNull QueryChangeListener listener) {
        verifyUIThread();
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

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    @UiThread
    public void removeChangeListener(@NonNull Query query, @NonNull ListenerToken token) {
        verifyUIThread();
        getAndVerifyDb();

        final List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        listeners.remove(token);

        query.removeChangeListener(token);
    }

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    @UiThread
    public void removeChangeListeners(@NonNull Query query) {
        verifyUIThread();

        final List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        for (ListenerToken token: listeners) { query.removeChangeListener(token); }

        listeners.clear();
    }

    @UiThread
    public void removeAllChangeListeners() {
        verifyUIThread();
        for (Query query: changeListeners.keySet()) { removeChangeListeners(query); }
    }

    @WorkerThread
    public void login(@NonNull String username, @NonNull char[] password) {
        verifyNotUIThread();

        if (!open.compareAndSet(false, true)) { return; }

        this.username = username;
        database = openDatabase(username);

        if (Config.get().isSyncEnabled()) { startReplication(username, password); }
    }

    public boolean isLoggedIn(DAO dao) {
        return ((dao == null) || this.equals(dao)) && (database != null);
    }

    @UiThread
    public void logout() { logout(false); }

    @UiThread
    public void logout(boolean deleteDb) {
        final Database db = shutdownDatabase();
        newInstance();
        if (db != null) { new LogoutTask(deleteDb).execute(db); }
    }

    // Called from the UI thread only once, in ToDo.onTerminate()
    @UiThread
    public void forceLogout() {
        final Database db = shutdownDatabase();
        if (db != null) { closeDatabase(db); }
    }

    @NonNull
    public String getUsername() {
        getAndVerifyDb();
        return username;
    }

    @NonNull
    public From createQuery(@NonNull SelectResult... results) {
        final Database db = getAndVerifyDb();
        return QueryBuilder.select(results).from(DataSource.database(db));
    }

    @WorkerThread
    @Nullable
    public Document fetch(@NonNull String id) {
        verifyNotUIThread();
        return getAndVerifyDb().getDocument(id);
    }

    @WorkerThread
    @Nullable
    public Document save(@NonNull MutableDocument doc) {
        verifyNotUIThread();
        final Database db = getAndVerifyDb();

        try {
            db.save(doc);
            return db.getDocument(doc.getId());
        }
        catch (CouchbaseLiteException e) { reportError(e); }

        return null;
    }

    @WorkerThread
    public void delete(@NonNull Document doc) {
        verifyNotUIThread();
        final Database db = getAndVerifyDb();

        try { db.delete(doc); }
        catch (CouchbaseLiteException e) { reportError(e); }
    }

    @WorkerThread
    public void deleteById(@NonNull String docId) {
        verifyNotUIThread();
        final Database db = getAndVerifyDb();

        try {
            final Document doc = fetch(docId);
            if (doc != null) { db.delete(doc); }
        }
        catch (CouchbaseLiteException e) { reportError(e); }
    }

    // -------------------------
    // Database operations
    // -------------------------

    @WorkerThread
    private Database openDatabase(String dbName) {
        try { return new Database(dbName, new DatabaseConfiguration()); }
        catch (CouchbaseLiteException e) { reportError(e); }
        return null;
    }

    @NonNull
    private Database getAndVerifyDb() {
        final Database db = database;
        if (db == null) {
            throw new IllegalStateException("Attempt to use the DB before logging in.");
        }
        return db;
    }

    @UiThread
    @Nullable
    private Database shutdownDatabase() {
        if (!open.compareAndSet(true, false)) { return null; }

        final Database db = database;
        if (db == null) { return null; }

        stopReplication();
        removeAllChangeListeners();

        return db;
    }

    // forceShutdown calls this from the UI thread.  Nobody else should.
    private void closeDatabase(Database db) {
        try {
            db.close();
            Log.e(TAG, "Database closed");
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to close database: " + db.getName(), e);
        }
    }

    private void deleteDatabase(Database db) {
        try {
            db.delete();
            Log.e(TAG, "Database deleted");
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to delete database: " + db.getName(), e);
        }
    }

    // -------------------------
    // Replicator operations
    // -------------------------
    @WorkerThread
    private void startReplication(@NonNull String username, @NonNull char[] password) {
        final Database db = getAndVerifyDb();

        final URI sgUri = getReplicationUri(username);
        if (sgUri == null) { return; }

        Log.i(TAG, "Starting replication to: " + sgUri);
        final Endpoint endpoint = new URLEndpoint(sgUri);

        final ReplicatorConfiguration config = new ReplicatorConfiguration(db, endpoint)
            .setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL)
            .setContinuous(true);

        // authentication
        config.setAuthenticator(new BasicAuthenticator(username, new String(password)));
        Arrays.fill(password, ' ');

        final Config.CcrState ccrState = Config.get().getCcrState();
        if (ccrState != Config.CcrState.OFF) {
            config.setConflictResolver(new SimpleConflictResolver());
        }

        final Replicator replicator = new Replicator(config);

        replicator.addChangeListener(this::changed);

        replicator.start(false);

        this.replicator = replicator;
    }

    void changed(ReplicatorChange change) {
        final AbstractReplicator.Status status = change.getStatus();
        Log.i(TAG, "Replicator status : " + status);

        updateState(status.getActivityLevel());

        final CouchbaseLiteException error = status.getError();
        if (error == null) { return; }

        if (error.getCode() == CBLError.Code.HTTP_AUTH_REQUIRED) { logout(); }

        reportError(error);
    }

    @Nullable
    private URI getReplicationUri(@NonNull String username) {
        try { return URI.create(Config.get().getSgUri()).normalize(); }
        catch (IllegalArgumentException e) { Log.d(TAG, "Login failed", e); }
        reportError(new CouchbaseLiteException(
            "Invalid SG URI",
            CBLError.Domain.CBLITE,
            CBLError.Code.INVALID_URL));

        return null;
    }

    private void stopReplication() {
        if (!Config.get().isSyncEnabled()) { return; }
        final Replicator repl = replicator;
        if (repl != null) { repl.stop(); }
        Log.i(TAG, "Replicator stopped");
    }

    private void reportError(@NonNull CouchbaseLiteException err) {
        final DAOListener listener;
        synchronized (this) {
            if (this.listener == null) {
                errors.add(err);
                return;
            }

            listener = this.listener;
        }

        Log.w(TAG, "DB error", err);
        deliverError(listener, err);
    }

    private void updateState(AbstractReplicator.ActivityLevel state) {
        final DAOListener listener;
        synchronized (this) {
            if (replicatorState == state) { return; }
            replicatorState = state;

            listener = this.listener;
        }

        if (listener != null) { deliverNewState(listener, state); }
    }

    // always deliver the error asynchronously, on the main thread
    private void deliverError(@NonNull DAOListener listener, @NonNull CouchbaseLiteException err) {
        mainHandler.post(() -> listener.onError(err));
    }

    // always deliver state asynchronously, on the main thread
    private void deliverNewState(@NonNull DAOListener listener, @NonNull AbstractReplicator.ActivityLevel state) {
        mainHandler.post(
            () -> listener.onNewState((Config.get().isSyncEnabled())
                ? state
                : AbstractReplicator.ActivityLevel.OFFLINE));
    }

    private void verifyNotUIThread() {
        if (isUIThread()) {
            throw new IllegalStateException("DB operations must not be run on the UI thread");
        }
    }

    private void verifyUIThread() {
        if (!isUIThread()) {
            throw new IllegalStateException("DB operations must not be run on the UI thread");
        }
    }

    private boolean isUIThread() {
        return Thread.currentThread().equals(mainHandler.getLooper().getThread());
    }
}
