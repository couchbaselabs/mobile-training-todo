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

import com.couchbase.lite.Database;
import com.couchbase.lite.LogLevel;
import com.couchbase.todo.BuildConfig;


public final class Config {
    private static final String TAG = "CONFIG";

    private static Config instance;

    @NonNull
    public static synchronized Config get() {
        if (instance == null) { instance = new Config(); }
        return instance;
    }

    private boolean loggingEnabled;
    private boolean loginRequired = BuildConfig.LOGIN_REQUIRED;
    private boolean ccrEnabled = BuildConfig.CCR_ENABLED;
    @Nullable
    private String dbName = BuildConfig.DB_NAME;
    @Nullable
    private String sgUri = BuildConfig.SG_URI;

    private Config() { setLoggingEnabled(BuildConfig.LOGGING_ENABLED); }

    public boolean isLoggingEnabled() { return loggingEnabled; }

    public boolean isLoginRequired() { return loginRequired || (dbName == null) || (sgUri != null); }

    public boolean isCcrEnabled() { return ccrEnabled; }

    public boolean isSyncEnabled() { return sgUri != null; }

    @Nullable
    public String getDbName() { return dbName; }

    @Nullable
    public String getSgUri() { return sgUri; }

    public boolean update(
        boolean loggingEnabled,
        boolean loginRequired,
        boolean ccrEnabled,
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

        if (this.ccrEnabled != ccrEnabled) {
            this.ccrEnabled = ccrEnabled;
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

    private void setLoggingEnabled(boolean enabled) {
        Database.log.getConsole().setLevel((loggingEnabled) ? LogLevel.VERBOSE : LogLevel.ERROR);
        loggingEnabled = enabled;
    }
}

