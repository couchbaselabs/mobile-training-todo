package com.couchbase.todo.db;

import java.util.Arrays;

import com.couchbase.lite.CouchbaseLiteException;


public class TaskDumper extends DocDumper<String> {
    @Override
    protected CouchbaseLiteException doInBackground(String... ids) {
        dumpDocs(Arrays.asList(ids));
        return null;
    }
}
