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
package com.couchbase.todo.service;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import androidx.annotation.WorkerThread;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.From;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.QueryChangeListener;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.tasks.LogoutTask;
import com.couchbase.todo.tasks.Scheduler;
import com.couchbase.todo.app.ToDo;


public final class DatabaseService {
    private static final String TAG = "SVC_DB";

    public static final String COLLECTION_LISTS = "lists";
    public static final String COLLECTION_TASKS = "tasks";
    public static final String COLLECTION_USERS = "users";

    @NonNull
    private static final Set<String> COLLECTION_NAMES = Set.of(COLLECTION_LISTS, COLLECTION_TASKS, COLLECTION_USERS);

    @NonNull
    private static final AtomicReference<DatabaseService> INSTANCE = new AtomicReference<>();

    @NonNull
    public static DatabaseService get() {
        final DatabaseService instance = INSTANCE.get();
        if (instance != null) { return instance; }
        INSTANCE.compareAndSet(null, new DatabaseService(ToDo.get(), ConfigurationService.get()));
        return INSTANCE.get();
    }

    @NonNull
    private final AtomicReference<Database> database = new AtomicReference<>();
    @NonNull
    private final AtomicReference<String> username = new AtomicReference<>();

    @NonNull
    private final Map<Query, List<ListenerToken>> queryListeners = new HashMap<>();

    @NonNull
    private final ToDo app;
    @NonNull
    private final ConfigurationService config;

    private DatabaseService(@NonNull ToDo app, @NonNull ConfigurationService config) {
        this.app = app;
        this.config = config;

        if (!config.isLoginRequired()) {
            final String dbName = config.getDbName();
            if (dbName == null) { throw new IllegalStateException("No name configured for the database."); }
            openDatabase(dbName);
        }
    }

    ///// Database

    @Nullable
    public Database createDb(@NonNull String dbName) {
        try { return new Database(dbName); }
        catch (CouchbaseLiteException e) { app.reportError(e); }
        return null;
    }

    @Nullable
    public Database getDb() { return database.get(); }

    @NonNull
    public String getUsername() {
        getAndVerifyDb();
        return username.get();
    }

    @NonNull
    public Set<Collection> getCollections() {
        final Set<Collection> collections = new HashSet<>();
        for (String collectionName: COLLECTION_NAMES) { collections.add(getAndVerifyCollection(collectionName)); }
        return collections;
    }

    @WorkerThread
    public void login(@NonNull String user, @NonNull char[] password) {
        Scheduler.assertNotMainThread();

        if (openDatabase(user) == null) { return; }

        if (config.isSyncEnabled()) { ReplicatorService.get().startReplication(user, password); }
    }

    public boolean isLoggedIn(@Nullable DatabaseService dao) {
        return ((dao == null) || this.equals(dao)) && (database.get() != null);
    }

    @UiThread
    public void logout() { logout(false); }

    @UiThread
    public void logout(boolean deleteDb) {
        INSTANCE.getAndSet(null);
        final Database db = shutdownDatabase();
        if (db != null) { new LogoutTask(this, deleteDb).execute(db); }
    }

    // Called in only one place: in ToDo.onTerminate(), on the UI Thread
    @UiThread
    public void forceLogout() {
        final Database db = shutdownDatabase();
        if (db != null) { closeDatabase(db); }
    }

    @WorkerThread
    public void logoutSafely(@NonNull Database db, boolean deleting) {
        Scheduler.assertNotMainThread();
        if (deleting) { deleteDatabase(db); }
        else { closeDatabase(db); }
    }

    ///// Document

    @WorkerThread
    @Nullable
    public Document saveDoc(@NonNull String collectionName, @NonNull MutableDocument doc) {
        Scheduler.assertNotMainThread();

        final Collection collection = getAndVerifyCollection(collectionName);
        try {
            collection.save(doc);
            return collection.getDocument(doc.getId());
        }
        catch (CouchbaseLiteException e) { ToDo.get().reportError(e); }

        return null;
    }

    @WorkerThread
    @Nullable
    public Document fetchDoc(@NonNull String collectionName, @NonNull String id) {
        Scheduler.assertNotMainThread();

        try { return getAndVerifyCollection(collectionName).getDocument(id); }
        catch (CouchbaseLiteException e) { app.reportError(e); }

        return null;
    }

    @WorkerThread
    @NonNull
    public List<String> getDocIdsForCollection(@NonNull String collectionName) {
        Scheduler.assertNotMainThread();
        return getIdsList(createQuery(collectionName, SelectResult.expression(Meta.id)));
    }

    @WorkerThread
    @NonNull
    public List<String> getTaskIdsForList(@NonNull String listID) {
        Scheduler.assertNotMainThread();
        return getIdsList(createQuery(
            COLLECTION_TASKS,
            SelectResult.expression(Meta.id))
            .where(Expression.property("taskList.id").equalTo(Expression.string(listID))));
    }

    @WorkerThread
    public void deleteDocById(@NonNull String collectionName, @NonNull String docId) {
        Scheduler.assertNotMainThread();
        try {
            final Collection collection = getAndVerifyCollection(collectionName);
            final Document doc = collection.getDocument(docId);
            if (doc != null) { collection.delete(doc); }
        }
        catch (CouchbaseLiteException e) { app.reportError(e); }
    }

    ///// Queries

    @NonNull
    public From createQuery(@NonNull String collectionName, @NonNull SelectResult... results) {
        return QueryBuilder.select(results).from(DataSource.collection(getAndVerifyCollection(collectionName)));
    }

    // Should, totally, verify that the query is against the currently open DB.
    // No api for that...
    @UiThread
    public void addQueryListener(@NonNull Query query, @NonNull QueryChangeListener listener) {
        Scheduler.assertMainThread();
        getAndVerifyDb();
        queryListeners.computeIfAbsent(query, k -> new ArrayList<>()).add(query.addChangeListener(listener));
    }

    @UiThread
    public void removeQueryListeners(@NonNull Query query) {
        Scheduler.assertMainThread();

        final List<ListenerToken> listeners = queryListeners.remove(query);
        if (listeners == null) { return; }

        for (ListenerToken token: listeners) { token.remove(); }
    }

    @UiThread
    public void removeAllQueryListeners() {
        Scheduler.assertMainThread();

        final Map<Query, List<ListenerToken>> queryListeners = new HashMap<>(this.queryListeners);
        this.queryListeners.clear();

        for (List<ListenerToken> listeners: queryListeners.values()) {
            if (listeners != null) {
                for (ListenerToken token: listeners) { token.remove(); }
            }
        }
    }

    // -------------------------
    // Private
    // -------------------------

    ///// Database

    @WorkerThread
    private Database openDatabase(@NonNull String userName) {
        try {
            final Database db = new Database(userName);
            if (database.compareAndSet(null, db)) {
                username.set(userName);
                return db;
            }
        }
        catch (CouchbaseLiteException e) { app.reportError(e); }
        return null;
    }

    @NonNull
    private Database getAndVerifyDb() {
        final Database db = database.get();
        if (db == null) {
            throw new IllegalStateException("Attempt to use the DB before logging in.");
        }
        return db;
    }

    @NonNull
    private Collection getAndVerifyCollection(@NonNull String collectionName) {
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

    @Nullable
    private Database shutdownDatabase() {
        final Database db = database.getAndSet(null);
        if (db == null) { return null; }

        ReplicatorService.get().stopReplication();
        removeAllQueryListeners();

        return db;
    }

    // forceShutdown calls this from the UI thread.  Nobody else should.
    private void closeDatabase(@NonNull Database db) {
        try {
            db.close();
            Log.e(TAG, "Database closed");
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to close database: " + db.getName(), e);
        }
    }

    private void deleteDatabase(@NonNull Database db) {
        try {
            db.delete();
            Log.e(TAG, "Database deleted");
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to delete database: " + db.getName(), e);
        }
    }

    ///// Queries

    @NonNull
    private List<String> getIdsList(@NonNull Query query) {
        final ResultSet docIdResults;
        final List<String> docIds = new ArrayList<>();
        try {
            docIdResults = query.execute();
            for (Result r = docIdResults.next(); r != null; r = docIdResults.next()) { docIds.add(r.getString(0)); }
        }
        catch (CouchbaseLiteException e) { Log.e(TAG, "Query failed: " + query, e); }
        return docIds;
    }
}
