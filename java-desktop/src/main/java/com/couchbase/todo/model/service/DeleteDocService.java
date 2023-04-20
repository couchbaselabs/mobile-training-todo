package com.couchbase.todo.model.service;

import javafx.concurrent.Service;
import javafx.concurrent.Task;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.todo.model.DB;


public class DeleteDocService extends Service<Void> {

    @NotNull
    private final String collectionName;
    @NotNull
    private final String docId;

    public DeleteDocService(@NotNull String collectionName, @NotNull String docId) {
        this.collectionName = collectionName;
        this.docId = docId;
        setExecutor(DB.get().getExecutor());
    }

    @Override
    protected Task<Void> createTask() {
        return new Task<Void>() {
            @Override
            protected Void call() throws CouchbaseLiteException {
                DB.get().deleteDocument(collectionName, docId);
                return null;
            }
        };
    }
}
