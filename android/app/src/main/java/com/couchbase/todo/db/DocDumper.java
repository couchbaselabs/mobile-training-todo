package com.couchbase.todo.db;

import android.os.AsyncTask;
import android.util.Log;

import androidx.annotation.WorkerThread;

import com.couchbase.lite.Document;

import java.util.List;


abstract class DocDumper<T> extends AsyncTask<T, Void, Exception> {
    public static final String TAG = "DOC DUMP";

    @WorkerThread
    protected final void dumpDocs(List<String> docIds) {
        for (String id: docIds) {
            Document doc = DAO.get().fetch(id);
            if (doc == null) { Log.w(TAG, "Document is null"); }
            else { Log.i(TAG, doc.toJSON()); }
        }
    }
}

