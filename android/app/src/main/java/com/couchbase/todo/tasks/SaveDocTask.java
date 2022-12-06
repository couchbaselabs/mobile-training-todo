package com.couchbase.todo.tasks;

import androidx.annotation.Nullable;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;


public final class SaveDocTask extends Scheduler.BackgroundTask<MutableDocument, Document> {
    private final String collectionName;

    public SaveDocTask(String collectionName) { this.collectionName = collectionName; }

    // This is not thread safe.  The docs might change on the submitting thread.
    @Nullable
    @Override
    protected Document doInBackground(@Nullable MutableDocument doc) {
        return (doc == null) ? null : DatabaseService.get().saveDoc(collectionName, doc);
    }
}
