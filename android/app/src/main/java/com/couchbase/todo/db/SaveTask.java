package com.couchbase.todo.db;

import android.os.AsyncTask;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;


public class SaveTask extends AsyncTask<MutableDocument, Void, List<Document>> {
    private volatile Consumer<List<Document>> listener;

    public SaveTask(Consumer<List<Document>> listener) { this.listener = listener; }

    @Override
    protected List<Document> doInBackground(MutableDocument... docs) {
        List<Document> savedDocs = new ArrayList<>();
        for (MutableDocument doc : docs) { savedDocs.add(DAO.get().save(doc)); }
        return savedDocs;
    }

    @Override
    protected void onCancelled() {
        super.onCancelled();
        listener = null;
    }

    @Override
    protected void onPostExecute(List<Document> documents) {
        if (listener!= null) { listener.accept(documents); }
    }
}
