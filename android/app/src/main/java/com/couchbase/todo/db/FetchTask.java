package com.couchbase.todo.db;

import android.os.AsyncTask;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

import com.couchbase.lite.Document;


public class FetchTask extends AsyncTask<String, Void, List<Document>> {
    private volatile Consumer<List<Document>> listener;

    public FetchTask(Consumer<List<Document>> listener) { this.listener = listener; }

    @Override
    protected List<Document> doInBackground(String... ids) {
        List<Document> savedDocs = new ArrayList<>();
        for (String id : ids) { savedDocs.add(DAO.get().fetch(id)); }
        return savedDocs;
    }

    @Override
    protected void onCancelled() {
        super.onCancelled();
        listener = null;
    }

    @Override
    protected void onPostExecute(List<Document> documents) {
        if (listener != null) { listener.accept(documents); }
    }
}
