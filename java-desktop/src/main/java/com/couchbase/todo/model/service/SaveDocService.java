package com.couchbase.todo.model.service;

import javafx.concurrent.Service;
import javafx.concurrent.Task;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.model.DB;


public class SaveDocService extends Service<Document> {
    private final String collectionName;
    private final MutableDocument document;

    public SaveDocService(String collectionName, MutableDocument document) {
        this.collectionName = collectionName;
        this.document = document;
        setExecutor(DB.get().getExecutor());
    }

    @Override
    protected Task<Document> createTask() {
        return new Task<Document>() {
            @Override
            protected Document call() throws CouchbaseLiteException {
                return DB.get().saveDocument(collectionName, document);
            }
        };
    }
}
