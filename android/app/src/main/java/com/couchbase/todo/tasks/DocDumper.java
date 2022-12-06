package com.couchbase.todo.tasks;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.WorkerThread;

import java.util.List;

import com.couchbase.lite.Document;
import com.couchbase.todo.service.DatabaseService;


abstract class DocDumper<T, R> extends Scheduler.BackgroundTask<T, R> {
    public static final String TAG = "DOC DUMP";

    @WorkerThread
    protected final void dumpDocs(@NonNull String collectionName, @Nullable List<String> docIds, String label) {
        if (null == docIds) { return; }
        for (String id: docIds) {
            Document doc = DatabaseService.get().fetchDoc(collectionName, id);
            if (doc != null) { Log.i(TAG, "=== " + label + ": " + doc.toJSON()); }
            else { Log.w(TAG, "Document " + id + " is null"); }
        }
    }
}

