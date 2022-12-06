package com.couchbase.todo.tasks;

import androidx.annotation.Nullable;

import java.util.List;

import com.couchbase.todo.service.DatabaseService;


public class TaskDumper extends DocDumper<String, Void> {

    @Nullable
    @Override
    protected Void doInBackground(@Nullable String id) {
        if (id != null) { dumpDocs(DatabaseService.COLLECTION_TASKS, List.of(id), "TASK"); }
        return null;
    }
}
