package com.couchbase.todo;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;

import com.couchbase.lite.Blob;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.QueryChange;
import com.couchbase.lite.QueryChangeListener;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;


public class TasksAdapter extends ArrayAdapter<String> {
    private static final String TAG = TasksAdapter.class.getSimpleName();

    private final TasksFragment fragment;
    private final Database db;
    private final String listID;

    public TasksAdapter(TasksFragment fragment, Database db, String listID) {
        super(fragment.getContext(), 0);
        this.fragment = fragment;
        this.db = db;
        this.listID = listID;

        query().addChangeListener(new QueryChangeListener() {
            @Override
            public void changed(QueryChange change) {
                clear();
                ResultSet rs = change.getResults();
                Result result;
                while ((result = rs.next()) != null) { add(result.getString(0)); }
                notifyDataSetChanged();
            }
        });
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        if (convertView == null) {
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_task, parent, false);
        }

        String docID = getItem(position);
        final Document task = db.getDocument(docID);
        if (task == null) { throw new IllegalStateException("Document does not exists: " + docID); }

        // image view
        ImageView imageView = convertView.findViewById(R.id.photo);
        Blob thumbnail = task.getBlob("image");
        if (thumbnail != null) { Glide.with(getContext()).load(thumbnail.getContent()).into(imageView); }
        else { imageView.setImageResource(R.drawable.ic_camera_light); }
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
        boolean checked = checkedProperty != null && checkedProperty.booleanValue();
        checkBox.setChecked(checked);
        checkBox.setOnClickListener(new android.view.View.OnClickListener() {
            @Override
            public void onClick(android.view.View view) {
                updateCheckedStatus(task.toMutable(), checkBox.isChecked());
            }
        });

        return convertView;
    }

    private Query query() {
        SelectResult SR_DOC_ID = SelectResult.expression(Meta.id);
        SelectResult SR_TASK = SelectResult.property("task");
        SelectResult SR_COMPLETE = SelectResult.property("complete");
        SelectResult SR_IMAGE = SelectResult.property("image");
        Expression EXPR_TYPE = Expression.property("type");
        Expression EXPR_TASKLIST_ID = Expression.property("taskList.id");
        Ordering ORDERBY_CREATED_AT = Ordering.property("createdAt");
        Ordering ORDERBY_TASK = Ordering.property("task");

        return QueryBuilder.select(SR_DOC_ID, SR_TASK, SR_COMPLETE, SR_IMAGE)
            .from(DataSource.database(db))
            .where(EXPR_TYPE.equalTo(Expression.string("task"))
                .and(EXPR_TASKLIST_ID.equalTo(Expression.string(listID))))
            .orderBy(ORDERBY_CREATED_AT, ORDERBY_TASK);
    }

    private Document updateCheckedStatus(MutableDocument task, boolean checked) {
        task.setBoolean("complete", checked);
        try {
            db.save(task);
            return db.getDocument(task.getId());
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to save the document", e);
            //TODO: Error handling
            return null;
        }
    }
}
