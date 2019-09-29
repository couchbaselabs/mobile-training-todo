package com.couchbase.lite.todo.support;

import com.couchbase.lite.Database;
import com.couchbase.lite.Replicator;

public class UserContext {
    private String username;

    private Database database;

    private Replicator replicator;

    UserContext(String username, Database database) {
        this.username = username;
        this.database = database;
        this.replicator = replicator;
    }

    public String getUsername() {
        return this.username;
    }

    public Database getDatabase() {
        return this.database;
    }

    Replicator getReplicator() {
        return this.replicator;
    }

    void setReplicator(Replicator replicator) {
        this.replicator = replicator;
    }
}
