package com.couchbase.todo;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.couchbase.lite.Blob;
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

public class TasksAdapter extends ArrayAdapter<Document> {

    private static final String TAG = TasksAdapter.class.getSimpleName();

    private TasksFragment fragment;
    private Database db;
    private String listID;


    public TasksAdapter(TasksFragment fragment, Database db, String listID, List<Document> objects) {
        super(fragment.getContext(), 0, objects);
        this.fragment = fragment;
        this.db = db;
        this.listID = listID;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        if (convertView == null)
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_task, parent, false);

        final Document task = getItem(position);
        if (task == null)
            return convertView;

        // image view
        ImageView imageView = convertView.findViewById(R.id.photo);
        Blob thumbnail = task.getBlob("image");
        if (thumbnail != null)
            Glide.with(getContext()).load(thumbnail.getContent()).into(imageView);
        else
            imageView.setImageResource(R.drawable.ic_camera_light);
        imageView.setOnClickListener(new android.view.View.OnClickListener() {
            @Override
            public void onClick(android.view.View v) {
                fragment.dispatchTakePhotoIntent(task);
            }
        });


        // text
        TextView text = convertView.findViewById(R.id.text);
        text.setText(task.getString("task"));

        // checkbox
        final CheckBox checkBox = convertView.findViewById(R.id.checked);
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
        Log.e(TAG, "reload()");

        clear();

        ResultSet rs = Query.select()
                .from(DataSource.database(db))
                .where(Expression.property("type").equalTo("task").and(Expression.property("taskList.id").equalTo(listID)))
                //.where(Expression.property("type").equalTo("task"))
                .orderBy(OrderBy.property("createdAt"), OrderBy.property("task"))
                .run();
        QueryRow row;
        while ((row = rs.next()) != null) {
            add(row.getDocument());
            Log.e(TAG, "\t- " + row.getDocumentID() + "\n\t\t" + row.getDocument().toMap());
        }
    }

    // -------------------------
    // Database - CRUD
    // -------------------------
    private void updateCheckedStatus(Document task, boolean checked) {
        task.set("complete", checked);
        db.save(task);
    }
}
