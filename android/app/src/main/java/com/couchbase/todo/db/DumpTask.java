package com.couchbase.todo.db;

import android.os.AsyncTask;
import android.util.Log;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

public final class DumpTask extends AsyncTask<String,Void,Void> {
    //private volatile Consumer<List<Document>> listener;
   //public FetchTask(Consumer<List<Document>> listener) { this.listener = listener; }
    @Override
    protected Void doInBackground(String... ids) {
        //dump each task/each list
        for (String id : ids) {
            Document doc = DAO.get().fetch(id);
            Log.i("doc",doc.toJSON());
            if(doc.getValue("type").equals("task-list")){
                //if its a list, also log all tasks in that list
                try {
                    ResultSet allTasks = DAO.get().getAllTasksFromList(doc.getId());
                    for(Result result: allTasks){
                        Log.i("allTasks", result.toJSON());
                    }
                } catch (CouchbaseLiteException e) {
                    e.printStackTrace();
                }
            }

        }
        return null;
    }
}
