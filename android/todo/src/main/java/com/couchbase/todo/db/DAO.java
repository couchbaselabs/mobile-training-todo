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

import android.content.Context;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

    private static DAO instance;

    public static synchronized DAO get() {
        if (instance == null) { instance = new DAO(); }
        return instance;
    }


    private final Map<Query, List<ListenerToken>> changeListeners = new HashMap<>();

    private final Thread mainThread;

    private String username;
    private Replicator replicator;
    private Database database;

    // Called from the UI thread only once, in ToDo.onCreate()
    private DAO() {
        mainThread = Looper.getMainLooper().getThread();

        if (Config.get().isLoginEnabled()) { return; }

        // open the default database
        username = Config.get().getDbName();
        try { database = openDatabase(username); }
        catch (CouchbaseLiteException e) { throw new IllegalStateException("cannot open default DB: " + username); }
    }

    public boolean isLoggedIn() { return database != null; }

    public String login(Context ctxt, String username, String password) {
        if (TextUtils.isEmpty(username)) { throw new IllegalArgumentException("empty username name"); }

        verifyThread();

        if (!isLoggedIn()) {
            this.username = username;

            try { database = openDatabase(username); }
            catch (CouchbaseLiteException e) { return e.getMessage(); }

            if (Config.get().isSyncEnabled()) { startReplication(ctxt, username, password); }
        }

        return null;
    }

    public void logout() {
        verifyThread();

        if (isLoggedIn()) {
            if (Config.get().isSyncEnabled()) { replicator.stop(); }

            for (Query query : changeListeners.keySet()) { removeChangeListeners(query); }

            closeDatabase();
        }

        // clean the slate...
        instance = new DAO();
    }

    public String getUsername() {
        verifyDB();
        return username;
    }

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    public ListenerToken addChangeListener(Query query, QueryChangeListener listener) {
        verifyDB();

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
    public void removeChangeListener(Query query, ListenerToken token) {
        verifyDB();

        List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        listeners.remove(token);

        query.removeChangeListener(token);
    }

    // Should, totally, verify that this query is against the DB that is open.
    // No api for that...
    public void removeChangeListeners(Query query) {
        verifyDB();

        List<ListenerToken> listeners = changeListeners.get(query);
        if (listeners == null) { return; }

        for (ListenerToken token : listeners) { query.removeChangeListener(token); }

        listeners.clear();
    }

    public From createQuery(SelectResult... results) {
        verifyDB();
        return QueryBuilder.select(results).from(DataSource.database(database));
    }

    public Document fetchDocument(String id) {
        verifyDB();
        verifyThread();
        return database.getDocument(id);
    }

    public Document save(MutableDocument doc) {
        verifyDB();
        verifyThread();

        try {
            database.save(doc);
            return database.getDocument(doc.getId());
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to save the document", e);
        }

        return null;
    }

    public void delete(Document list) {
        verifyDB();
        verifyThread();

        try { database.delete(list); }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to delete the document", e);
        }
    }

    // -------------------------
    // Database operations
    // -------------------------

    private Database openDatabase(String dbname) throws CouchbaseLiteException {
        return new Database(dbname, new DatabaseConfiguration());
    }

    private void closeDatabase() {
        for (int i = 0; i < 5; i++) {
            try {
                database.close();
                return;
            }
            catch (CouchbaseLiteException ex) {
                if (ex.getCode() == CBLError.Code.BUSY) {
                    try { Thread.sleep(200); }
                    catch (InterruptedException ignore) { }
                    continue;
                }

                Log.w(TAG, "Failed closing DB: " + ex);
                break;
            }
        }
    }

    // -------------------------
    // Replicator operations
    // -------------------------
    private void startReplication(Context ctxt, String username, String password) {
        String uriStr = Config.get().getSgUrl();
        URI uri;
        try { uri = new URI(uriStr); }
        catch (URISyntaxException e) {
            Log.e(TAG, "Failed parse URI: " + uriStr, e);
            return;
        }

        Endpoint endpoint = new URLEndpoint(uri);
        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint)
            .setReplicatorType(ReplicatorConfiguration.ReplicatorType.PUSH_AND_PULL)
            .setContinuous(true);

        if (Config.get().isCcrEnabled()) { config.setConflictResolver(new SimpleConflictResolver()); }

        // authentication
        if ((username != null) && (password != null)) {
            config.setAuthenticator(new BasicAuthenticator(username, password));
        }

        replicator = new Replicator(config);

        replicator.addChangeListener(change -> changed(ctxt, change));

        replicator.start();
    }

    private void changed(Context ctxt, ReplicatorChange change) {
        AbstractReplicator.Status status = change.getStatus();
        Log.i(TAG, "Replicator status : " + status);

        CouchbaseLiteException error = status.getError();
        if (error == null) { return; }

        String msg = (error.getCode() == 401)
            ? "Authentication Error: Your username or password is not correct."
            : "Replication failure: " + error.getMessage();

        Toast.makeText(ctxt, msg, Toast.LENGTH_LONG).show();

        logout();
    }

    private void verifyDB() {
        if (!isLoggedIn()) { throw new IllegalStateException("Attempt to use the DB before logging in."); }
    }

    // for now, don't enforce it
    private void verifyThread() {
        try {
            if (Thread.currentThread().equals(mainThread)) {
                throw new IllegalStateException("DB operations must not be run on the UI thread");
            }
        }
        catch (IllegalStateException e) {
            Log.w(TAG, "Thread abuse!!!", e);
        }
    }
}
