package com.couchbase.todo.db;


import android.util.Log;

import com.couchbase.lite.CouchbaseLiteException;


public class DbDumper extends DocDumper<String> {

    @Override
    protected CouchbaseLiteException doInBackground(String... ids) {
        try { dumpDocs(DAO.get().getAllDocIds()); }
        catch (CouchbaseLiteException e) { return e; }
        return null;
    }

    @Override
    protected void onPostExecute(Exception e) {
        if (e != null) { throw new IllegalArgumentException(e); }
    }
}
