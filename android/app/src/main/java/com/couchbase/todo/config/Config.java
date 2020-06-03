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
package com.couchbase.todo.config;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Objects;

import com.couchbase.lite.ConsoleLogger;
import com.couchbase.lite.Database;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;
import com.couchbase.todo.BuildConfig;


public final class Config {
    private static final String TAG = "CONFIG";

    public enum CcrState {OFF, LOCAL, REMOTE}

    private static Config instance;

    @NonNull
    public static synchronized Config get() {
        if (instance == null) { instance = new Config(); }
        return instance;
    }

    private boolean loggingEnabled;
    private boolean loginRequired = BuildConfig.LOGIN_REQUIRED;
    private CcrState ccrState;

    @Nullable
    private String dbName = BuildConfig.DB_NAME;
    @Nullable
    private String sgUri = BuildConfig.SG_URI;

    private Config() {
        setLoggingEnabled(BuildConfig.LOGGING_ENABLED);
        setCcrState(BuildConfig.CCR_LOCAL_WINS, BuildConfig.CCR_REMOTE_WINS);
    }

    public boolean isLoggingEnabled() { return loggingEnabled; }

    public boolean isLoginRequired() { return loginRequired || (dbName == null) || (sgUri != null); }

    public CcrState getCcrState() { return ccrState; }

    public boolean isSyncEnabled() { return sgUri != null; }

    @Nullable
    public String getDbName() { return dbName; }

    @Nullable
    public String getSgUri() { return sgUri; }

    public boolean update(
        boolean loggingEnabled,
        boolean loginRequired,
        CcrState ccrState,
        @Nullable String dbName,
        @Nullable String sgUri) {
        boolean updated = false;

        if (this.loggingEnabled != loggingEnabled) {
            setLoggingEnabled(loggingEnabled);
            updated = true;
        }

        if (this.loginRequired != loginRequired) {
            this.loginRequired = loginRequired;
            updated = true;
        }

        if (this.ccrState != ccrState) {
            this.ccrState = ccrState;
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

        return updated;
    }

    private void setCcrState(boolean localWins, boolean remoteWins) {
        ccrState = (remoteWins) ? CcrState.REMOTE : ((localWins) ? CcrState.LOCAL : CcrState.OFF);
    }

    private void setLoggingEnabled(boolean enabled) {
        final ConsoleLogger logger = Database.log.getConsole();
        logger.setDomains(LogDomain.ALL_DOMAINS);
        logger.setLevel((enabled) ? LogLevel.DEBUG : LogLevel.ERROR);
        loggingEnabled = enabled;
    }
}
