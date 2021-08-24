package com.couchbase.todo.model.service;

import javafx.concurrent.Service;
import javafx.concurrent.Task;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.model.DB;


public class SaveDocService extends Service<Document> {
    private final MutableDocument document;

    public SaveDocService(MutableDocument document) {
        this.document = document;
        setExecutor(DB.get().getExecutor());
    }

    @Override
    protected Task<Document> createTask() {
        return new Task<>() {
            @Override
            protected Document call() throws Exception {
                return DB.get().saveDocument(document);
            }
        };
    }
}
