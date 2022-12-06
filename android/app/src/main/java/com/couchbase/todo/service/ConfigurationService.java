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

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.ConsoleLogger;
import com.couchbase.lite.Database;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;
import com.couchbase.todo.BuildConfig;


public final class ConfigurationService {
    private static final String TAG = "SVC_CONFIG";

    public enum CcrState {OFF, LOCAL, REMOTE}

    private static final AtomicReference<ConfigurationService> INSTANCE = new AtomicReference<>();

    @NonNull
    public static ConfigurationService get() {
        final ConfigurationService config = INSTANCE.get();
        if (config != null) { return config; }
        INSTANCE.compareAndSet(null, new ConfigurationService());
        return INSTANCE.get();
    }


    @Nullable
    private String dbName = BuildConfig.DB_NAME;
    @Nullable
    private String sgUri = BuildConfig.SG_URI;

    @NonNull
    private CcrState ccrState = CcrState.OFF;

    private boolean loginRequired = BuildConfig.LOGIN_REQUIRED;
    private boolean loggingEnabled;

    private int retries;
    private int waitTime;

    private ConfigurationService() {
        setLoggingEnabled(BuildConfig.LOGGING_ENABLED);
        setCcrState(BuildConfig.CCR_LOCAL_WINS, BuildConfig.CCR_REMOTE_WINS);
    }

    public boolean isLoginRequired() { return loginRequired || (dbName == null) || (sgUri != null); }

    public boolean isLoggingEnabled() { return loggingEnabled; }

    public boolean isSyncEnabled() { return sgUri != null; }

    @Nullable
    public String getDbName() { return dbName; }

    @Nullable
    public String getSgUri() { return sgUri; }

    @NonNull
    public CcrState getCcrState() { return ccrState; }

    public int getRetries() { return retries; }

    public int getWaitTime() { return waitTime; }

    public boolean update(
        boolean loggingEnabled,
        boolean loginRequired,
        boolean localWins,
        boolean remoteWins,
        @Nullable String dbName,
        @Nullable String sgUri,
        int retries,
        int waitTime) {
        final CcrState oldCcrState = ccrState;
        setCcrState(localWins, remoteWins);
        boolean updated = ccrState.equals(oldCcrState);

        if (this.loggingEnabled != loggingEnabled) {
            setLoggingEnabled(loggingEnabled);
            updated = true;
        }

        if (this.loginRequired != loginRequired) {
            this.loginRequired = loginRequired;
            updated = true;
        }

        if (!Objects.equals(this.dbName, dbName)) {
            this.dbName = dbName;
            updated = true;
        }

        if (!Objects.equals(this.sgUri, sgUri)) {
            this.sgUri = sgUri;
            updated = true;
        }

        if (this.retries != retries) {
            this.retries = retries;
            updated = true;
        }

        if (this.waitTime != waitTime) {
            this.waitTime = waitTime;
            updated = true;
        }

        return updated;
    }

    private void setLoggingEnabled(boolean enabled) {
        final ConsoleLogger logger = Database.log.getConsole();
        logger.setDomains(LogDomain.ALL_DOMAINS);
        logger.setLevel((enabled) ? LogLevel.DEBUG : LogLevel.ERROR);
        loggingEnabled = enabled;
    }

    private void setCcrState(boolean localWins, boolean remoteWins) {
        ccrState = (remoteWins) ? CcrState.REMOTE : ((localWins) ? CcrState.LOCAL : CcrState.OFF);
    }
}
