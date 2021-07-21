package com.couchbase.todo.model;

import java.util.Objects;

import com.couchbase.lite.ConsoleLogger;
import com.couchbase.lite.Database;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;
import com.couchbase.todo.TodoApp;


public final class Config {
    private static Config instance;

    private boolean loggingEnabled = TodoApp.LOG_ENABLED;
    private boolean loginRequired = TodoApp.LOGIN_REQUIRED;

    private int attempts;
    private int attemptsWaitTime;

    private String dbName = TodoApp.DB_DIR;
    private String sgUri = TodoApp.SYNC_URL;

    private TodoApp.CR_MODE cr_mode;

    private Config() {
        setLoggingEnabled(TodoApp.LOG_ENABLED);
        setCcrState(TodoApp.CCR_LOCAL_WINS, TodoApp.CCR_REMOTE_WINS);
    }

    public static synchronized Config get() {
        if (instance == null) { instance = new Config(); }
        return instance;
    }

    public boolean isLoggingEnabled() { return loggingEnabled; }

    public boolean isLoginRequired() { return loginRequired || dbName == null || sgUri != null; }

    public TodoApp.CR_MODE getCr_mode() { return cr_mode; }

    public String getDbName() { return dbName; }

    public String getSgUri() { return sgUri; }

    public int getAttempts() { return attempts; }

    public int getAttemptsWaitTime() { return attemptsWaitTime; }

    public boolean update(
        boolean loggingEnabled,
        boolean loginRequired,
        TodoApp.CR_MODE cr_mode,
        String dbName,
        String sgUri,
        int attempts,
        int attemptsWaitTime) {

        boolean updated = false;

        if (this.loggingEnabled != loggingEnabled) {
            setLoggingEnabled(loggingEnabled);
            updated = true;
        }

        if (this.loginRequired != loginRequired) {
            this.loginRequired = loginRequired;
            updated = true;
        }

        if (this.cr_mode != cr_mode) {
            this.cr_mode = cr_mode;
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

        if (this.attempts != attempts) {
            this.attempts = attempts;
            updated = true;
        }

        if (this.attemptsWaitTime != attemptsWaitTime) {
            this.attemptsWaitTime = attemptsWaitTime;
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

    private void setCcrState(boolean local, boolean remote) {
        cr_mode = (local) ? TodoApp.CR_MODE.LOCAL : ((remote) ? TodoApp.CR_MODE.REMOTE : TodoApp.CR_MODE.DEFAULT);
    }

}
