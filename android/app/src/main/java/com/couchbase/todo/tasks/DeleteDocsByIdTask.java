package com.couchbase.todo.tasks;

import androidx.annotation.Nullable;

import com.couchbase.todo.service.DatabaseService;


public final class DeleteDocsByIdTask extends Scheduler.BackgroundTask<String, Void> {
    private final String collectionName;

    public DeleteDocsByIdTask(String collectionName) { this.collectionName = collectionName; }

    @Nullable
    @Override
    protected Void doInBackground(String docId) {
        DatabaseService.get().deleteDocById(collectionName, docId);
        return null;
    }
}
