package com.couchbase.todo;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
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
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryRow;
import com.couchbase.lite.ResultSet;

import java.util.List;

public class UsersAdapter extends ArrayAdapter<Document> {
    private static final String TAG = UsersAdapter.class.getSimpleName();

    private UsersFragment fragment;
    private Database db;
    private String listID;


    public UsersAdapter(UsersFragment fragment, Database db, String listID, List<Document> objects) {
        super(fragment.getContext(), 0, objects);
        this.fragment = fragment;
        this.db = db;
        this.listID = listID;
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        if (convertView == null)
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_user, parent, false);

        final Document user = getItem(position);
        if (user == null)
            return convertView;

        // text
        TextView userText = convertView.findViewById(R.id.user_name);
        userText.setText(user.getString("username"));

        return convertView;
    }

    // -------------------------
    // Database - Query
    // -------------------------
    public void reload() {

        Log.e(TAG, "reload()");

        clear();

        ResultSet rs = Query.select()
                .from(DataSource.database(db))
                .where(Expression.property("type").equalTo("task-list.user")
                        .and(Expression.property("taskList.id").equalTo(listID)))
                .run();
        QueryRow row;
        while ((row = rs.next()) != null) {
            add(row.getDocument());
            Log.e(TAG, "\t- " + row.getDocumentID() + "\n\t\t" + row.getDocument().toMap());
        }
    }
}