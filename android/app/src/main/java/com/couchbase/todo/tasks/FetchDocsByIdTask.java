package com.couchbase.todo.tasks;

import androidx.annotation.Nullable;

import java.util.function.Consumer;

import com.couchbase.lite.Document;
import com.couchbase.todo.service.DatabaseService;


public final class FetchDocsByIdTask extends Scheduler.BackgroundTask<String, Document> {
    private final String collectionName;
    private final Consumer<Document> receiver;

    public FetchDocsByIdTask(String collectionName, Consumer<Document> receiver) {
        this.collectionName = collectionName;
        this.receiver = receiver;
    }

    @Nullable
    @Override
    protected Document doInBackground(@Nullable String id) {
        return (id == null) ? null : DatabaseService.get().fetchDoc(collectionName, id);
    }

    @Override
    protected void onComplete(@Nullable Document doc) { receiver.accept(doc); }
}
