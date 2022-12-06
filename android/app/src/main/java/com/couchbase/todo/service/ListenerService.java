//
// Copyright (c) 2022 Couchbase, Inc All rights reserved.
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

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.UiThread;
import androidx.annotation.WorkerThread;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableEntryException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;

import com.couchbase.lite.AbstractReplicatorConfiguration;
import com.couchbase.lite.ClientCertificateAuthenticator;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.ListenerCertificateAuthenticator;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.lite.ReplicatorChangeListener;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.TLSIdentity;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;
import com.couchbase.todo.StringUtils;
import com.couchbase.todo.app.ToDo;
import com.couchbase.todo.tasks.DBCopyTask;


public class ListenerService {
    private final String TAG = "SVC_LISTEN";

    private static final String EXT_KEY_STORE = "teststore.p12";
    private static final String INT_KEY_STORE = "AndroidKeyStore";
    private static final String EXT_KEY_STORE_TYPE = "PKCS12";
    private static final String KEY_PASSWORD = "couchbase";
    private static final String TODO_CERTIFICATE = "test-chain";
    private static final String CLIENT_KEY_ALIAS = "todo-client-id";
    private static final String SERVER_KEY_ALIAS = "todo-server-id";

    private static final String BASE_DB_COPY_NAME = "_copy";

    public static class DBCopier implements AutoCloseable, ReplicatorChangeListener {
        @NonNull
        private final URLEndpointListener listener;
        @NonNull
        private final ReplicatorChangeListener replListener;
        @NonNull
        private final ReplicatorService.LiveReplication repl;

        @NonNull
        private final AtomicReference<ReplicatorActivityLevel> state = new AtomicReference<>(null);

        public DBCopier(
            @NonNull URLEndpointListener listener,
            @NonNull ReplicatorChangeListener replListener,
            @NonNull ReplicatorService replication,
            @NonNull ReplicatorConfiguration config) {
            this.listener = listener;
            this.replListener = replListener;
            this.repl = replication.createReplicator(config, this);
        }

        public void start() { repl.start(); }

        @Override
        public void changed(@NonNull ReplicatorChange change) {
            final ReplicatorActivityLevel level = change.getStatus().getActivityLevel();
            if (level == state.getAndSet(level)) { return; }
            switch (level) {
                case STOPPED:
                case OFFLINE:
                case IDLE:
                    close();
                    break;
                default:
                    break;
            }
            replListener.changed(change);
        }

        @Override
        public void close() {
            repl.stop();
            listener.stop();
        }
    }

    private static final AtomicInteger PORT_FACTORY = new AtomicInteger(30000);

    private static final AtomicReference<ListenerService> LISTENER = new AtomicReference<>();

    @NonNull
    public static ListenerService get() {
        final ListenerService instance = LISTENER.get();
        if (instance != null) { return instance; }
        LISTENER.compareAndSet(null, new ListenerService(ToDo.get(), DatabaseService.get(), ReplicatorService.get()));
        return LISTENER.get();
    }


    @NonNull
    private final ToDo app;
    @NonNull
    private final DatabaseService dao;
    @NonNull
    private final ReplicatorService replication;

    @NonNull
    private final AtomicReference<KeyStore> externalKeyStore = new AtomicReference<>(null);
    @NonNull
    private final AtomicReference<KeyStore> internalKeyStore = new AtomicReference<>(null);

    private ListenerService(
        @NonNull ToDo app,
        @NonNull DatabaseService dao,
        @NonNull ReplicatorService replication) {
        this.app = app;
        this.dao = dao;
        this.replication = replication;
    }

    @UiThread
    public void copyDb(@NonNull ReplicatorChangeListener listener, @NonNull Consumer<DBCopier> receiver) {
        new DBCopyTask(this, listener, receiver).execute(null);
    }

    @NonNull
    @WorkerThread
    public DBCopier copyDb(@NonNull ReplicatorChangeListener changeListener) {
        final String dbName = StringUtils.getUniqueName(dao.getUsername() + BASE_DB_COPY_NAME, 3);

        final TLSIdentity clientId = createIdentity(CLIENT_KEY_ALIAS);
        final TLSIdentity listenerId = createIdentity(SERVER_KEY_ALIAS);
        final X509Certificate listenerCert = (X509Certificate) listenerId.getCerts().get(0);

        final URLEndpointListener listener = startListener(dbName, listenerId, clientId.getCerts().get(1));

        final URI endpoint;
        try { endpoint = new URI("wss", null, "localhost", listener.getPort(), "/" + dbName, null, null); }
        catch (URISyntaxException e) { throw new IllegalStateException("Cannot create endpoint"); }

        final ReplicatorConfiguration config = new ReplicatorConfiguration(new URLEndpoint(endpoint))
            .setContinuous(false)
            .setHeartbeat(AbstractReplicatorConfiguration.DISABLE_HEARTBEAT)
            .setAuthenticator(new ClientCertificateAuthenticator(clientId))
            .setPinnedServerX509Certificate(listenerCert);

        final DBCopier copier = new DBCopier(listener, changeListener, replication, config);
        copier.start();
        return copier;
    }

    @Nullable
    @WorkerThread
    private URLEndpointListener startListener(String dbName, TLSIdentity serverIdentity, Certificate clientCert) {
        final Database dstDb = dao.createDb(dbName);
        if (dstDb == null) { return null; }

        final URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(dao.getCollections());
        config.setPort(PORT_FACTORY.getAndIncrement());
        config.setAuthenticator(new ListenerCertificateAuthenticator(List.of(clientCert)));
        config.setTlsIdentity(serverIdentity);

        final URLEndpointListener listener = new URLEndpointListener(config);

        try { listener.start(); }
        catch (CouchbaseLiteException e) { throw new IllegalStateException("Cannot start listener", e); }

        return listener;
    }

    @Nullable
    @WorkerThread
    private TLSIdentity createIdentity(String aliasRoot) {
        final String alias = StringUtils.getUniqueName(aliasRoot, 3).toLowerCase();

        importEntry(TODO_CERTIFICATE, alias);

        try { return TLSIdentity.getIdentity(alias); }
        catch (CouchbaseLiteException e) { throw new IllegalStateException("Cannot create identity for " + alias, e); }
    }

    private void importEntry(@NonNull String srcAlias, @NonNull String dstAlias) {
        final KeyStore externalStore = getExternalKeyStore();
        final KeyStore internalStore = getInternalKeyStore();

        try {
            internalStore.setEntry(
                dstAlias,
                externalStore.getEntry(srcAlias, new KeyStore.PasswordProtection(KEY_PASSWORD.toCharArray())),
                null
            );
        }
        catch (UnrecoverableEntryException | KeyStoreException | NoSuchAlgorithmException ignore) {
            throw new IllegalStateException("Cannot import cert for alias: " + srcAlias);
        }
    }

    @Nullable
    @WorkerThread
    private KeyStore getInternalKeyStore() {
        if (internalKeyStore.get() != null) { return internalKeyStore.get(); }

        try {
            final KeyStore ks = KeyStore.getInstance(INT_KEY_STORE);
            ks.load(null);
            internalKeyStore.compareAndSet(null, ks);
        }
        catch (CertificateException | KeyStoreException | IOException | NoSuchAlgorithmException e) {
            throw new IllegalStateException("Failed loading the internal KeyStore", e);
        }

        return internalKeyStore.get();
    }

    @Nullable
    @WorkerThread
    private KeyStore getExternalKeyStore() {
        if (externalKeyStore.get() != null) { return externalKeyStore.get(); }

        try (InputStream in = app.getAssets().open(EXT_KEY_STORE)) {
            final KeyStore ks = KeyStore.getInstance(EXT_KEY_STORE_TYPE);
            ks.load(in, KEY_PASSWORD.toCharArray());
            externalKeyStore.compareAndSet(null, ks);
        }
        catch (IOException | CertificateException | KeyStoreException | NoSuchAlgorithmException e) {
            throw new IllegalStateException("Failed loading the external KeyStore", e);
        }

        return externalKeyStore.get();
    }
}
