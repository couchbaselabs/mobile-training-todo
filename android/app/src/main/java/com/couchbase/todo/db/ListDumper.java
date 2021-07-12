package com.couchbase.todo.db;

import com.couchbase.lite.CouchbaseLiteException;

import java.util.Arrays;


public class ListDumper extends DocDumper<String> {
    @Override
    protected CouchbaseLiteException doInBackground(String... ids) {
        for (String id: ids) {
            dumpDocs(Arrays.asList(new String[] {id}));
            try { dumpDocs(DAO.get().getTaskIdsFromList(id)); }
            catch (CouchbaseLiteException e) { return e; }
        }
        return null;
    }

    @Override
    protected void onPostExecute(Exception e) {
        if (e != null) { throw new IllegalArgumentException(e); }
    }
}
