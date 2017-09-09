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
import com.couchbase.lite.LiveQuery;
import com.couchbase.lite.LiveQueryChange;
import com.couchbase.lite.LiveQueryChangeListener;
import com.couchbase.lite.Log;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;

import java.util.HashMap;
import java.util.Map;

public class LiveListsAdapter extends ArrayAdapter<String> {
    private static final String TAG = LiveListsAdapter.class.getSimpleName();

    private Database db;
    private LiveQuery listsLiveQuery = null;
    private LiveQuery incompTasksCountLiveQuery = null;
    private Map<String, Integer> incompCounts = new HashMap<>();

    public LiveListsAdapter(Context context, Database db) {
        super(context, 0);
        this.db = db;

        this.listsLiveQuery = listsLiveQuery();
        this.listsLiveQuery.addChangeListener(new LiveQueryChangeListener() {
            @Override
            public void changed(LiveQueryChange change) {
                clear();
                ResultSet rs = change.getRows();
                Result result;
                while ((result = rs.next()) != null) {
                    add(result.getString(0));
                }
                notifyDataSetChanged();
            }
        });
        this.listsLiveQuery.run();

        this.incompTasksCountLiveQuery = incompTasksCountLiveQuery();
        this.incompTasksCountLiveQuery.addChangeListener(new LiveQueryChangeListener() {
            @Override
            public void changed(LiveQueryChange change) {
                incompCounts.clear();
                ResultSet rs = change.getRows();
                Result result;
                while ((result = rs.next()) != null) {
                    Log.e(TAG, "result -> " + result.toMap());
                    incompCounts.put(result.getString(0), result.getInt(1));
                }
                notifyDataSetChanged();
            }
        });
        this.incompTasksCountLiveQuery.run();
    }

    @Override
    protected void finalize() throws Throwable {
        if (listsLiveQuery != null) {
            listsLiveQuery.stop();
            listsLiveQuery = null;
        }
        if (incompTasksCountLiveQuery != null) {
            incompTasksCountLiveQuery.stop();
            incompTasksCountLiveQuery = null;
        }
        super.finalize();
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

        Log.e(TAG, "getView(): pos -> %d, docID -> %s, name -> %s, name2 -> %s, all -> %s", position, list.getId(), list.getString("name"), list.getObject("name"), list.toMap());
        return convertView;
    }

    private LiveQuery listsLiveQuery() {


        return Query.select(SelectResult.expression(Expression.meta().getId()))
                .from(DataSource.database(db))
                .where(Expression.property("type").equalTo("task-list"))
                .orderBy(Ordering.property("name").ascending())
                .toLive();
    }

    private LiveQuery incompTasksCountLiveQuery() {
        Expression exprType = Expression.property("type");
        Expression exprComplete = Expression.property("complete");
        Expression exprTaskListId = Expression.property("taskList.id");
        SelectResult srTaskListID = SelectResult.expression(exprTaskListId);
        SelectResult srCount = SelectResult.expression(Function.count(1));
        return Query.select(srTaskListID, srCount)
                .from(DataSource.database(db))
                .where(exprType.equalTo("task").and(exprComplete.equalTo(false)))
                .groupBy(exprTaskListId)
                .toLive();
    }
}
