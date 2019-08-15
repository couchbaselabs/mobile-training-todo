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
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import androidx.annotation.WorkerThread;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;

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

    private class LogoutTask extends AsyncTask<Void, Void, Void> {
        private final Database db;

        public LogoutTask(Database db) { this.db = db; }

        @Override
        protected Void doInBackground(Void... unused) {
            closeDatabase(db);
            return null;
        }
    }

    private static volatile DAO instance;

    @NonNull
    public static synchronized DAO get() {
        if (instance == null) { instance = new DAO(); }
        return instance;
    }


    private final Map<Query, List<ListenerToken>> changeListeners = new HashMap<>();

    private List<CouchbaseLiteException> errors = new ArrayList<>();
    private Consumer<CouchbaseLiteException> listener;

    private final Handler mainHandler;

    private final AtomicBoolean open = new AtomicBoolean();

    private volatile Database database;
    private volatile String username;

    private Replicator replicator;

    // Called from the UI thread only once, in ToDo.onCreate()
    private DAO() {
        mainHandler = new Handler(Looper.getMainLooper());

        if (!Config.get().isLoginEnabled()) {
            // open a default database
            open.set(true);
            username = Config.get().getDbName();
            database = openDatabase(username);
        }
    }

    public void registerErrorListener(@Nullable Consumer<CouchbaseLiteException> listener) {
        final List<CouchbaseLiteException> errors;
        synchronized (this) {
            if (Objects.equals(this.listener, listener)) { return; }

            this.listener = listener;
            if (this.listener == null) { return; }

            errors = this.errors;
            this.errors = new ArrayList<>();
        }

        for (CouchbaseLiteException err : errors) { deliverError(listener, err); }
    }

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    @UiThread
    @NonNull
    public ListenerToken addChangeListener(@NonNull Query query, @NonNull QueryChangeListener listener) {
        verifyUIThread();
        getAndVerifyDb();

        List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) {
            listeners = new ArrayList<>();
            changeListeners.put(query, listeners);
        }

        ListenerToken token = query.addChangeListener(listener);
        listeners.add(token);

        return token;
    }

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    @UiThread
    public void removeChangeListener(@NonNull Query query, @NonNull ListenerToken token) {
        verifyUIThread();
        getAndVerifyDb();

        List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        listeners.remove(token);

        query.removeChangeListener(token);
    }

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    @UiThread
    public void removeChangeListeners(@NonNull Query query) {
        verifyUIThread();

        List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        for (ListenerToken token : listeners) { query.removeChangeListener(token); }

        listeners.clear();
    }

    @UiThread
    public void removeAllChangeListeners() {
        verifyUIThread();
        for (Query query : changeListeners.keySet()) { removeChangeListeners(query); }
    }

    @WorkerThread
    public boolean login(@NonNull String username, @Nullable String password) {
        if (TextUtils.isEmpty(username)) { throw new IllegalArgumentException("empty username name"); }
        verifyNotUIThread();

        if (!open.compareAndSet(false, true)) { return false; }

        this.username = username;
        database = openDatabase(username);

        return startReplication(username, password);
    }

    public boolean isLoggedIn(DAO dao) { return ((dao == null) || this.equals(dao)) && (database != null); }

    @UiThread
    public void logout() {
        final Database db = shutdownDatabase();
        instance = new DAO();
        if (db != null) { new LogoutTask(db).execute(); }
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

        try { db.delete(fetch(docId)); }
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
        if (db == null) { throw new IllegalStateException("Attempt to use the DB before logging in."); }
        return db;
    }

    @UiThread
    @Nullable
    private Database shutdownDatabase() {
        if (!open.compareAndSet(true, false)) { return null; }

        final Database db = database;
        if (db == null) { return null; }

        stopReplicatation();
        removeAllChangeListeners();

        return db;
    }

    // forceShutdown calls this from the UI thread.  Nobody else should.
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

    // -------------------------
    // Replicator operations
    // -------------------------
    @WorkerThread
    private boolean startReplication(String username, String password) {
        if (!Config.get().isSyncEnabled()) { return true; }

        String uriStr = Config.get().getSgUrl();
        if (uriStr == null) {
            badUri(uriStr);
            return false;
        }

        URI uri;
        try { uri = new URI(uriStr); }
        catch (URISyntaxException e) {
            badUri(uriStr);
            return false;
        }

        final Database db = getAndVerifyDb();

        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(db, endpoint)
            .setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL)
            .setContinuous(true);

        if (Config.get().isCcrEnabled()) { config.setConflictResolver(new SimpleConflictResolver()); }

        // authentication
        if ((username != null) && (password != null)) {
            config.setAuthenticator(new BasicAuthenticator(username, password));
        }

        final Replicator replicator = new Replicator(config);

        replicator.addChangeListener(this::changed);

        replicator.start();

        this.replicator = replicator;

        return true;
    }

    private void stopReplicatation() {
        if (!Config.get().isSyncEnabled()) { return; }
        final Replicator repl = replicator;
        if (repl != null) { repl.stop(); }
    }

    private void changed(ReplicatorChange change) {
        AbstractReplicator.Status status = change.getStatus();
        Log.i(TAG, "Replicator status : " + status);

        CouchbaseLiteException error = status.getError();
        if (error == null) { return; }

        reportError(error);

        if (error.getCode() == CBLError.Code.HTTP_AUTH_REQUIRED) { logout(); }
    }

    private void badUri(@Nullable String uri) {
        reportError(new CouchbaseLiteException(
            "Failed parse URI: " + uri,
            CBLError.Domain.CBLITE,
            CBLError.Code.INVALID_URL));
    }

    private void reportError(@NonNull CouchbaseLiteException err) {
        final Consumer<CouchbaseLiteException> listener;
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

    // always deliver the error asynchronously, on the main thread
    private void deliverError(@NonNull Consumer<CouchbaseLiteException> listener, @NonNull CouchbaseLiteException err) {
        mainHandler.post(() -> listener.accept(err));
    }

    private void verifyNotUIThread() {
        if (isUIThread()) { throw new IllegalStateException("DB operations must not be run on the UI thread"); }
    }

    private void verifyUIThread() {
        if (!isUIThread()) { throw new IllegalStateException("DB operations must not be run on the UI thread"); }
    }

    private boolean isUIThread() { return Thread.currentThread().equals(mainHandler.getLooper().getThread()); }
}
