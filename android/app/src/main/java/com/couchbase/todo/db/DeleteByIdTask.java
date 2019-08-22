package com.couchbase.todo.db;

import android.os.AsyncTask;


public final class DeleteByIdTask extends AsyncTask<String, Void, Void> {
    @Override
    protected Void doInBackground(String... docIds) {
        for (String docId : docIds) { DAO.get().deleteById(docId); }
        return null;
    }
}
