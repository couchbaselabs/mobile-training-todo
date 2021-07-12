package com.couchbase.todo.db;


import java.util.ArrayList;
import java.util.List;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Query;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;


public final class DbUtils {
    private DbUtils(){}

    /**
     * Get a list of doc ids from database
     * @param query
     * @return a list of doc ids
     */
    public static List<String> getIdsList(Query query) throws CouchbaseLiteException {
        ResultSet docIdsRs = query.execute();
        List<String> docIds = new ArrayList<>();
        for (Result id = docIdsRs.next(); id != null; id = docIdsRs.next()) { docIds.add(id.getString(0)); }
        return docIds;
    }
}
