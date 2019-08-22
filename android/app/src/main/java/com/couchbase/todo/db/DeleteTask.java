package com.couchbase.todo.db;

import android.os.AsyncTask;

import com.couchbase.lite.Document;


public final class DeleteTask extends AsyncTask<Document, Void, Void> {
    @Override
    protected Void doInBackground(Document... docs) {
        for (Document doc : docs) { DAO.get().delete(doc); }
        return null;
    }
}
