package com.couchbase.todo.model;

import java.util.Objects;

import com.couchbase.lite.ConsoleLogger;
import com.couchbase.lite.Database;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;
import com.couchbase.todo.TodoApp;


public final class Config {

    private final boolean loggingEnabled;
    private final boolean loginRequired;
    private final int attempts;
    private final int attemptsWaitTime;

    private final String dbName;
    private final String sgUri;

    private final TodoApp.CR_MODE cr_mode;

    public static class Builder {
        private boolean loggingEnabled = TodoApp.LOG_ENABLED;
        private boolean loginRequired = TodoApp.LOGIN_REQUIRED;

        private String dbName = TodoApp.DB_DIR;
        private String sgUri = TodoApp.SYNC_URL;

        private int attempts;
        private int attemptsWaitTime;

        private TodoApp.CR_MODE cr_mode = TodoApp.SYNC_CR_MODE;

        public Builder logging(boolean loggingEnabled) {
            this.loggingEnabled = loggingEnabled;
            return this;
        }

        public Builder login(boolean loginRequired) {
            this.loginRequired = loginRequired;
            return this;
        }

        public Builder dbName(String dbName) {
            this.dbName = dbName;
            return this;
        }

        public Builder sgUri(String sgUri) {
            this.sgUri = sgUri;
            return this;
        }

        public Builder attempts(int attempts) {
            this.attempts = attempts;
            return this;
        }

        public Builder waitTime(int attemptsWaitTime) {
            this.attemptsWaitTime = attemptsWaitTime;
            return this;
        }

        public Builder mode(TodoApp.CR_MODE cr_mode) {
            this.cr_mode = cr_mode;
            return this;
        }

        public Config build() {
            return new Config(this);
        }
    }

    public Config(Builder builder) {
        this.loggingEnabled = builder.loggingEnabled;
        this.loginRequired = builder.loginRequired;
        this.dbName = builder.dbName;
        this.sgUri = builder.sgUri;
        this.attempts = builder.attempts;
        this.attemptsWaitTime = builder.attemptsWaitTime;
        this.cr_mode = builder.cr_mode;
    }

    public static Builder builder() {
        return new Builder();
    }

    public boolean isLoggingEnabled() { return loggingEnabled; }

    public boolean isLoginRequired() { return loginRequired || dbName == null || sgUri != null; }

    public TodoApp.CR_MODE getCr_mode() { return cr_mode; }

    public String getDbName() { return dbName; }

    public String getSgUri() { return sgUri; }

    public int getAttempts() { return attempts; }

    public int getAttemptsWaitTime() { return attemptsWaitTime; }
}
