package com.couchbase.todo.tasks;


import android.util.Log;

import androidx.annotation.Nullable;

import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.todo.service.DatabaseService;


public class DbDumper extends DocDumper<Void, Void> {

    @Override
    @Nullable
    protected Void doInBackground(@Nullable Void ignore) throws CouchbaseLiteException {
        final DatabaseService dao = DatabaseService.get();
        Log.i(TAG, "======= DUMP DB: " + dao.getDb().getName());

        for (Collection collection: dao.getDb().getCollections()) {
            final String collectionName = collection.getName();
            Log.i(TAG, "===== COLLECTION: " + collection.getScope().getName() + "." + collectionName);
            dumpDocs(collectionName, dao.getDocIdsForCollection(collectionName), "DOC");
        }

        return null;
    }

    @Override
    protected void onCancelled(@Nullable Exception err) {
        if (err != null) { throw new IllegalArgumentException(err); }
    }
}
