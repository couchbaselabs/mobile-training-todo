package com.couchbase.todo.model.service;

import javafx.concurrent.Service;
import javafx.concurrent.Task;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Document;
import com.couchbase.todo.model.DB;


public class FetchDocService extends Service<Document> {

    @NotNull
    private final String collectionName;
    @NotNull
    private final String docId;

    public FetchDocService(@NotNull String collectionName, @NotNull String docId) {
        this.collectionName = collectionName;
        this.docId = docId;
        setExecutor(DB.get().getExecutor());
    }

    @Override
    protected Task<Document> createTask() {
        return new Task<>() {
            @Override
            protected Document call() throws CouchbaseLiteException {
                return DB.get().getDocument(collectionName, docId);
            }
        };
    }
}
