package com.couchbase.todo.model.service;

import javafx.concurrent.Service;
import javafx.concurrent.Task;
import org.jetbrains.annotations.NotNull;

import com.couchbase.todo.model.DB;


public class DeleteDocService extends Service<Void> {

    @NotNull
    private final String docId;

    public DeleteDocService(@NotNull String docId) {
        this.docId = docId;
        setExecutor(DB.get().getExecutor());
    }

    @Override
    protected Task<Void> createTask() {
        return new Task<>() {
            @Override
            protected Void call() throws Exception {
                DB.get().deleteDocument(docId);
                return null;
            }
        };
    }

}
