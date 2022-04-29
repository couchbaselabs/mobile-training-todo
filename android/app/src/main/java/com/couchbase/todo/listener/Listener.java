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
package com.couchbase.todo.listener;

import android.os.AsyncTask;

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
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.AbstractReplicatorConfiguration;
import com.couchbase.lite.ClientCertificateAuthenticator;
import com.couchbase.lite.Conflict;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.ListenerCertificateAuthenticator;
import com.couchbase.lite.ListenerToken;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorType;
import com.couchbase.lite.TLSIdentity;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.URLEndpointListener;
import com.couchbase.lite.URLEndpointListenerConfiguration;
import com.couchbase.lite.internal.utils.Fn;
import com.couchbase.lite.internal.utils.StringUtils;
import com.couchbase.todo.app.ToDo;
import com.couchbase.todo.db.DAO;


public class Listener {
    private final String TAG = "LISTENER";

    private static final String EXT_KEY_STORE = "teststore.p12";
    private static final String INT_KEY_STORE = "AndroidKeyStore";
    private static final String EXT_KEY_STORE_TYPE = "PKCS12";
    private static final String KEY_PASSWORD = "couchbase";
    private static final String TODO_CERTIFICATE = "test-chain";
    private static final String CLIENT_KEY_ALIAS = "todo-client-id";
    private static final String SERVER_KEY_ALIAS = "todo-server-id";

    private static final String BASE_DB_COPY_NAME = "_copy";

    private static final Map<String, String> X509_ATTRIBUTES;
    static {
        final Map<String, String> m = new HashMap<>();
        m.put(TLSIdentity.CERT_ATTRIBUTE_COMMON_NAME, "ToDo");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION, "Couchbase");
        m.put(TLSIdentity.CERT_ATTRIBUTE_ORGANIZATION_UNIT, "Mobile");
        m.put(TLSIdentity.CERT_ATTRIBUTE_EMAIL_ADDRESS, "lite@couchbase.com");
        X509_ATTRIBUTES = Collections.unmodifiableMap(m);
    }

    public static class DBCopier implements AutoCloseable, Fn.Consumer<ReplicatorActivityLevel> {
        private final Fn.Consumer<ReplicatorActivityLevel> stateListener;
        private final Database dstDb;
        private final URLEndpointListener listener;
        private final Replicator repl;

        private final AtomicReference<ReplicatorActivityLevel> state = new AtomicReference<>(null);

        private ListenerToken token;

        public DBCopier(
            Fn.Consumer<ReplicatorActivityLevel> stateListener,
            Database dstDb,
            URLEndpointListener listener,
            Replicator repl) {
            this.stateListener = stateListener;
            this.dstDb = dstDb;
            this.listener = listener;
            this.repl = repl;
        }

        public void setToken(ListenerToken token) { this.token = token; }

        public Database getDatabase() { return this.dstDb; }

        @Override
        public void accept(@Nullable ReplicatorActivityLevel level) {
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
            stateListener.accept(level);
        }

        @Override
        public void close() {
            repl.removeChangeListener(token);
            repl.stop();
            listener.stop();
        }
    }

    private static class DBCopyTask extends AsyncTask<Void, Void, DBCopier> {
        private final Fn.Consumer<ReplicatorActivityLevel> listener;
        private final Fn.Consumer<DBCopier> receiver;

        DBCopyTask(Fn.Consumer<ReplicatorActivityLevel> listener, Fn.Consumer<DBCopier> receiver) {
            this.listener = listener;
            this.receiver = receiver;
        }

        @Override
        protected DBCopier doInBackground(Void... ignore) { return Listener.get().copyDb(listener); }

        @Override
        protected void onPostExecute(DBCopier copier) { receiver.accept(copier); }
    }

    private static final AtomicInteger PORT_FACTORY = new AtomicInteger(30000);

    private static volatile Listener instance;

    @NonNull
    public static synchronized Listener get() {
        if (instance == null) { instance = new Listener(); }
        return instance;
    }


    private final AtomicReference<KeyStore> externalKeyStore = new AtomicReference<>(null);
    private final AtomicReference<KeyStore> internalKeyStore = new AtomicReference<>(null);

    @UiThread
    public void copyDb(Fn.Consumer<ReplicatorActivityLevel> listener, Fn.Consumer<DBCopier> receiver) {
        new DBCopyTask(listener, receiver).execute();
    }

    @WorkerThread
    private DBCopier copyDb(Fn.Consumer<ReplicatorActivityLevel> stateListener) {
        final DAO dao = DAO.get();

        final String dbName = StringUtils.getUniqueName(dao.getUsername() + BASE_DB_COPY_NAME, 3);
        final Database dstDb = createDatabase(dbName);

        final TLSIdentity clientId = createIdentity(CLIENT_KEY_ALIAS);
        final TLSIdentity listenerId = createIdentity(SERVER_KEY_ALIAS);

        final URLEndpointListener listener;
        final URI endpoint;
        final byte[] listenerCert;
        try {
            listener = startListener(dstDb, listenerId, clientId.getCerts().get(1));
            endpoint = new URI("wss", null, "localhost", listener.getPort(), "/" + dbName, null, null);
            listenerCert = listenerId.getCerts().get(0).getEncoded();
        }
        catch (URISyntaxException | CertificateEncodingException e) {
            throw new IllegalStateException("Cannot create endpoint");
        }

        final Replicator repl = new Replicator(new ReplicatorConfiguration(dao.getDb(), new URLEndpoint(endpoint))
            .setType(ReplicatorType.PUSH_AND_PULL)
            .setContinuous(false)
            .setHeartbeat(AbstractReplicatorConfiguration.DISABLE_HEARTBEAT)
            .setPinnedServerCertificate(listenerCert)
            .setAuthenticator(new ClientCertificateAuthenticator(clientId))
            .setConflictResolver(Conflict::getRemoteDocument)
            .setPullFilter((doc, flags) -> true)
            .setPullFilter((doc, flags) -> true));

        final DBCopier copier = new DBCopier(stateListener, dstDb, listener, repl);
        copier.setToken(repl.addChangeListener(change -> copier.accept(change.getStatus().getActivityLevel())));
        repl.start(true);

        return copier;
    }

    @WorkerThread
    private Database createDatabase(String dbName) {
        try { return new Database(dbName); }
        catch (CouchbaseLiteException e) { throw new IllegalStateException("Cannot create database: " + dbName, e); }
    }

    @WorkerThread
    private URLEndpointListener startListener(Database db, TLSIdentity serverIdentity, Certificate clientCert) {
        final URLEndpointListenerConfiguration config = new URLEndpointListenerConfiguration(db);
        config.setPort(PORT_FACTORY.getAndIncrement());
        config.setAuthenticator(new ListenerCertificateAuthenticator(Arrays.asList(clientCert)));
        config.setTlsIdentity(serverIdentity);

        final URLEndpointListener listener = new URLEndpointListener(config);

        try { listener.start(); }
        catch (CouchbaseLiteException e) { throw new IllegalStateException("Cannot start listener", e); }

        return listener;
    }

    private TLSIdentity createIdentity(String aliasRoot) {
        final String alias = StringUtils.getUniqueName(aliasRoot, 3).toLowerCase();

        importEntry(TODO_CERTIFICATE, alias);

        try { return TLSIdentity.getIdentity(alias); }
        catch (CouchbaseLiteException e) { throw new IllegalStateException("Cannot create identity for " + alias, e); }
    }

    private void importEntry(String srcAlias, String dstAlias) {
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

    private KeyStore getExternalKeyStore() {
        if (externalKeyStore.get() != null) { return externalKeyStore.get(); }

        try (InputStream in = ToDo.getAppContext().getAssets().open(EXT_KEY_STORE)) {
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
