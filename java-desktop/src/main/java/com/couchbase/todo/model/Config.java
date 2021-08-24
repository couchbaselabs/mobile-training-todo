package com.couchbase.todo.model;

import com.couchbase.todo.TodoApp;


public final class Config {

    public static class Builder {
        private boolean loggingEnabled = TodoApp.LOG_ENABLED;
        private boolean loginRequired = TodoApp.LOGIN_REQUIRED;
        private String dbName = TodoApp.DB_DIR;
        private String sgwUri = TodoApp.SYNC_URL;
        private TodoApp.CR_MODE crMode = TodoApp.SYNC_CR_MODE;
        private int attempts;
        private int attemptsWaitTime;

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

        public Builder sgwUri(String sgwUri) {
            this.sgwUri = sgwUri;
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
            this.crMode = cr_mode;
            return this;
        }

        public Config build() {
            return new Config(this);
        }
    }

    public static Builder builder() { return new Builder(); }

    private final boolean loggingEnabled;
    private final boolean loginRequired;
    private final int attempts;
    private final int attemptsWaitTime;
    private final String dbName;
    private final String sgwUri;
    private final TodoApp.CR_MODE crMode;

    private Config(Builder builder) {
        this.loggingEnabled = builder.loggingEnabled;
        this.loginRequired = builder.loginRequired;
        this.dbName = builder.dbName;
        this.sgwUri = builder.sgwUri;
        this.attempts = builder.attempts;
        this.attemptsWaitTime = builder.attemptsWaitTime;
        this.crMode = builder.crMode;
    }

    public boolean isLoggingEnabled() { return loggingEnabled; }

    public boolean isLoginRequired() { return loginRequired || dbName == null || sgwUri != null; }

    public TodoApp.CR_MODE getCrMode() { return crMode; }

    public String getDbName() { return dbName; }

    public String getSgwUri() { return sgwUri; }

    public int getAttempts() { return attempts; }

    public int getAttemptsWaitTime() { return attemptsWaitTime; }
}
