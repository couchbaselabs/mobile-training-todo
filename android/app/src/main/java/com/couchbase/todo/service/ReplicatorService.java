//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
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

import java.net.URI;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.BasicAuthenticator;
import com.couchbase.lite.CBLError;
import com.couchbase.lite.CollectionConfiguration;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorChangeListener;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorStatus;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.todo.app.ToDo;


public class ReplicatorService {
    private static final String TAG = "SVC_REPL";

    public static class LiveReplication {
        @NonNull
        public final Replicator replicator;
        @Nullable
        public final ListenerToken token;

        public LiveReplication(@NonNull Replicator replicator, @Nullable ListenerToken token) {
            this.replicator = replicator;
            this.token = token;
        }

        public void start() {
            replicator.start();
            Log.i(TAG, "Started replication to: " + replicator.getConfig().getTarget());
        }

        public void stop() {
            if (token != null) { token.remove(); }
            replicator.stop();
            Log.i(TAG, "Replicator stopped");
        }
    }

    @NonNull
    private static final AtomicReference<ReplicatorService> INSTANCE = new AtomicReference<>();

    @NonNull
    public static ReplicatorService get() {
        final ReplicatorService instance = INSTANCE.get();
        if (instance != null) { return instance; }
        INSTANCE.compareAndSet(null, new ReplicatorService(ToDo.get(), ConfigurationService.get(), DatabaseService.get()));
        return INSTANCE.get();
    }


    @NonNull
    private final ToDo app;
    @NonNull
    private final ConfigurationService config;
    @NonNull
    private final DatabaseService dao;

    @NonNull
    private final AtomicReference<LiveReplication> replication = new AtomicReference<>();

    private ReplicatorService(@NonNull ToDo app, @NonNull ConfigurationService config, @NonNull DatabaseService dao) {
        this.app = app;
        this.config = config;
        this.dao = dao;
    }

    public void startReplication(@NonNull String username, @NonNull char[] password) {
        final URI sgUri = getReplicationUri();
        if (sgUri == null) { return; }

        final ReplicatorConfiguration config = new ReplicatorConfiguration(new URLEndpoint(sgUri))
            .setContinuous(true)
            .setAuthenticator(new BasicAuthenticator(username, password));

        final LiveReplication repl = createReplicator(config, this::onChange);
        replication.set(repl);
        repl.start();
    }

    @NonNull
    public LiveReplication createReplicator(
        @NonNull ReplicatorConfiguration replConfig,
        @Nullable ReplicatorChangeListener listener) {
        final CollectionConfiguration collConfig = new CollectionConfiguration();
        final ConfigurationService.CcrState ccrState = config.getCcrState();
        if (ccrState != ConfigurationService.CcrState.OFF) { collConfig.setConflictResolver(new ConfigurableConflictResolver()); }

        replConfig.addCollections(dao.getCollections(), collConfig)
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setMaxAttempts(config.getRetries())
            .setMaxAttemptWaitTime(config.getWaitTime());

        final Replicator repl = new Replicator(replConfig);
        final ListenerToken token = (listener == null) ? null : repl.addChangeListener(listener);

        return new LiveReplication(repl, token);
    }

    public void stopReplication() {
        if (!config.isSyncEnabled()) { return; }
        final LiveReplication repl = replication.getAndSet(null);
        if (repl != null) { repl.stop(); }
    }

    void onChange(@NonNull ReplicatorChange change) {
        final ReplicatorStatus status = change.getStatus();
        Log.i(TAG, "Replicator status : " + status);

        app.updateReplicatorState(status.getActivityLevel());

        final CouchbaseLiteException error = status.getError();
        if (error == null) { return; }

        if (error.getCode() == CBLError.Code.HTTP_AUTH_REQUIRED) { dao.logout(); }

        app.reportError(error);
    }

    @Nullable
    private URI getReplicationUri() {
        try { return URI.create(config.getSgUri()).normalize(); }
        catch (IllegalArgumentException e) { Log.d(TAG, "Login failed", e); }

        app.reportError(new CouchbaseLiteException(
            "Invalid SG URI",
            CBLError.Domain.CBLITE,
            CBLError.Code.INVALID_URL));

        return null;
    }
}
