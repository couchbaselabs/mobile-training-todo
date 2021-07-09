package com.couchbase.todo.db;

import android.os.AsyncTask;
import android.util.Log;

import androidx.annotation.WorkerThread;

import com.couchbase.lite.Document;

import java.util.List;


abstract class DocDumper<T> extends AsyncTask<T, Void, Exception> {
    public static final String DOC_LOGGER = "DOC DUMP";
    public static final String NULL_WARNING_LOGGER = "NULL DOC";

    @WorkerThread
    protected final void dumpDocs(List<String> docIds) {
        for (String id: docIds) {
            Document doc = DAO.get().fetch(id);
            if (doc == null) { Log.w(NULL_WARNING_LOGGER, "A document is null"); }
            else { Log.i(DOC_LOGGER, doc.toJSON()); }
        }
    }
}

