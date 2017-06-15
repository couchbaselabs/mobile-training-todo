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
import com.couchbase.lite.Log;
import com.couchbase.lite.OrderBy;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryRow;
import com.couchbase.lite.ResultSet;

import java.util.List;

public class ListsAdapter extends ArrayAdapter<Document> {
    private static final String TAG = ListsAdapter.class.getSimpleName();

    private Database db;

    public ListsAdapter(Context context, Database db, List<Document> objects) {
        super(context, 0, objects);
        this.db = db;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        Document list = getItem(position);
        if (convertView == null)
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_list, parent, false);
        TextView text = convertView.findViewById(R.id.text);
        text.setText(list.getString("name"));
        Log.e(TAG, "getView(): pos -> %d, docID -> %s, name -> %s, name2 -> %s, all -> %s", position, list.getId(), list.getString("name"), list.getObject("name"), list.toMap());
        return convertView;
    }

    // -------------------------
    // Database - Query
    // -------------------------
    public void reload() {
        Log.e(TAG, "reload()");

        clear();

        Log.e(TAG, "DB COUNT: %d", db.getCount());

        ResultSet rs = Query.select()
                .from(DataSource.database(db))
                .where(Expression.property("type").equalTo("task-list"))
                .orderBy(OrderBy.property("name").ascending())
                .run();
        QueryRow row;
        while ((row = rs.next()) != null) {
            add(row.getDocument());
            Log.e(TAG, "\t- " + row.getDocumentID() + "\n\t\t" + row.getDocument().toMap());
        }
    }
}
