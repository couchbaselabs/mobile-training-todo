package com.couchbase.todo;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.OrderBy;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryRow;
import com.couchbase.lite.ResultSet;

import java.util.List;

public class TasksAdapter extends ArrayAdapter<Document> {
    private Database db;
    private String listID;

    public TasksAdapter(Context context, Database db, String listID, List<Document> objects) {
        super(context, 0, objects);
        this.db = db;
        this.listID = listID;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        final Document task = getItem(position);

        if (convertView == null) {
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_task, parent, false);
        }

        ImageView imageView = (ImageView) convertView.findViewById(R.id.photo);
        imageView.setImageResource(R.drawable.ic_camera_light);//
        imageView.setOnClickListener(new android.view.View.OnClickListener() {
            @Override
            public void onClick(android.view.View v) {
                Toast.makeText(getContext(), "Not implmented yet.", Toast.LENGTH_LONG).show();
            }
        });

        TextView text = (TextView) convertView.findViewById(R.id.text);
        text.setText(task.getString("task"));

        final CheckBox checkBox = (CheckBox) convertView.findViewById(R.id.checked);
        Boolean checkedProperty = task.getBoolean("complete");
        boolean checked = checkedProperty != null ? checkedProperty.booleanValue() : false;
        checkBox.setChecked(checked);
        checkBox.setOnClickListener(new android.view.View.OnClickListener() {
            @Override
            public void onClick(android.view.View view) {
                updateCheckedStatus(task, checkBox.isChecked());
            }
        });

        return convertView;
    }

    // -------------------------
    // Database - Query
    // -------------------------
    public void reload() {
        clear();

        ResultSet rs = Query.select()
                .from(DataSource.database(db))
                .where(Expression.property("type").equalTo("task")
                        .add(Expression.property("taskList.id").equalTo(listID)))
                .orderBy(OrderBy.property("createdAt"), OrderBy.property("task"))
                .run();
        QueryRow row;
        while ((row = rs.next()) != null) {
            add(row.getDocument());
        }
    }

    // -------------------------
    // Database - CRUD
    // -------------------------
    private void updateCheckedStatus(Document task, boolean checked) {
        task.set("complete", checked);
        task.save();
    }
}
