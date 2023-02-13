package com.couchbase.lite.todo.support;

import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.todo.model.Task;
import com.couchbase.lite.todo.model.TaskList;
import com.couchbase.lite.todo.model.TaskListUser;


public class UserContext {
    private final String username;
    private final Database database;

    private Replicator replicator;

    UserContext(String username, Database database) {
        this.username = username;
        this.database = database;
    }

    public String getUsername() { return this.username; }

    public List<Collection> getCollections() {
        return Stream.of(TaskList.COLLECTION_LISTS, Task.COLLECTION_TASKS, TaskListUser.COLLECTION_USERS)
            .map(this::getDataSource).collect(Collectors.toList());
    }

    public Collection getDataSource(String collectionName) {
        try {
            final Collection collection = database.getCollection(collectionName);
            return (collection != null)
                ? collection
                : database.createCollection(collectionName);
        }
        catch (CouchbaseLiteException e) {
            throw new IllegalStateException("Cannot create collection: " + collectionName);
        }
    }

    Replicator getReplicator() { return this.replicator; }

    void setReplicator(Replicator replicator) { this.replicator = replicator; }
}
