package com.couchbase.todo.tasks;

import androidx.annotation.Nullable;

import java.util.List;

import com.couchbase.todo.service.DatabaseService;


public class ListDumper extends DocDumper<String, Void> {

    @Nullable
    @Override
    protected Void doInBackground(@Nullable String id) {
        if (id == null) { return null; }
        dumpDocs(DatabaseService.COLLECTION_LISTS, List.of(id), "LIST");
        dumpDocs(DatabaseService.COLLECTION_TASKS, DatabaseService.get().getTaskIdsForList(id), "TASK");
        return null;
    }

    @Override
    protected void onCancelled(@Nullable Exception err) {
        if (err != null) { throw new IllegalArgumentException(err); }
    }
}
