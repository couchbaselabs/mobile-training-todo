package com.couchbase.todo;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Function;
import com.couchbase.lite.Meta;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryChange;
import com.couchbase.lite.QueryChangeListener;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.internal.support.Log;

import java.util.HashMap;
import java.util.Map;

public class ListsAdapter extends ArrayAdapter<String> {
    private static final String TAG = ListsAdapter.class.getSimpleName();

    private Database db;
    private Query listsQuery = null;
    private Query incompTasksCountQuery = null;
    private Map<String, Integer> incompCounts = new HashMap<>();

    public ListsAdapter(Context context, Database db) {
        super(context, 0);

        if (db == null) throw new IllegalArgumentException();
        this.db = db;

        this.listsQuery = listsQuery();
        this.listsQuery.addChangeListener(new QueryChangeListener() {
            @Override
            public void changed(QueryChange change) {
                clear();
                ResultSet rs = change.getResults();
                Result result;
                while ((result = rs.next()) != null) {
                    add(result.getString(0));
                }
                notifyDataSetChanged();
            }
        });

        this.incompTasksCountQuery = incompTasksCountQuery();
        this.incompTasksCountQuery.addChangeListener(new QueryChangeListener() {
            @Override
            public void changed(QueryChange change) {
                incompCounts.clear();
                ResultSet rs = change.getResults();
                Result result;
                while ((result = rs.next()) != null) {
                    Log.e(TAG, "result -> " + result.toMap());
                    incompCounts.put(result.getString(0), result.getInt(1));
                }
                notifyDataSetChanged();
            }
        });
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        String id = getItem(position);
        Document list = db.getDocument(id);
        if (convertView == null)
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_list, parent, false);

        TextView text = convertView.findViewById(R.id.text);
        text.setText(list.getString("name"));

        TextView countText = convertView.findViewById(R.id.task_count);
        if (incompCounts.get(list.getId()) != null) {
            countText.setText(String.valueOf(((int) incompCounts.get(list.getId()))));
        } else {
            countText.setText("");
        }

        Log.e(TAG, "getView(): pos -> %d, docID -> %s, name -> %s, name2 -> %s, all -> %s", position, list.getId(), list.getString("name"), list.getValue("name"), list.toMap());
        return convertView;
    }

    private Query listsQuery() {
        return Query.select(SelectResult.expression(Meta.id))
                .from(DataSource.database(db))
                .where(Expression.property("type").equalTo(Expression.string("task-list")))
                .orderBy(Ordering.property("name").ascending());
    }

    private Query incompTasksCountQuery() {
        Expression exprType = Expression.property("type");
        Expression exprComplete = Expression.property("complete");
        Expression exprTaskListId = Expression.property("taskList.id");
        SelectResult srTaskListID = SelectResult.expression(exprTaskListId);
        SelectResult srCount = SelectResult.expression(Function.count(Expression.all()));
        return Query.select(srTaskListID, srCount)
                .from(DataSource.database(db))
                .where(exprType.equalTo(Expression.string("task")).and(exprComplete.equalTo(Expression.booleanValue(false))))
                .groupBy(exprTaskListId);
    }
}
