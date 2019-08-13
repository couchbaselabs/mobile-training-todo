//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.todo.ui;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.couchbase.lite.Blob;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.R;
import com.couchbase.todo.TasksFragment;
import com.couchbase.todo.db.DAO;

import androidx.annotation.NonNull;


public class TasksAdapter extends ArrayAdapter<String> {
    private static final String TAG = TasksAdapter.class.getSimpleName();

    private final TasksFragment fragment;
    private final String listID;
    private final Query query;

    public TasksAdapter(TasksFragment fragment, String listID) {
        super(fragment.getContext(), 0);
        this.fragment = fragment;
        this.listID = listID;

        query = query();
        DAO.get().addChangeListener(
            query,
            change -> {
                clear();
                ResultSet rs = change.getResults();
                Result result;
                while ((result = rs.next()) != null) { add(result.getString(0)); }
                notifyDataSetChanged();
            });
    }

    @NonNull
    @Override
    public View getView(int position, View convertView, @NonNull ViewGroup parent) {
        if (convertView == null) {
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_task, parent, false);
        }

        String docID = getItem(position);
        final Document task = DAO.get().fetchDocument(docID);
        if (task == null) { throw new IllegalStateException("Document does not exists: " + docID); }

        // image view
        ImageView imageView = convertView.findViewById(R.id.photo);
        Blob thumbnail = task.getBlob("image");
        if (thumbnail != null) { Glide.with(getContext()).load(thumbnail.getContent()).into(imageView); }
        else { imageView.setImageResource(R.drawable.ic_camera_light); }
        imageView.setOnClickListener(v -> fragment.dispatchTakePhotoIntent(task));

        // text
        TextView text = convertView.findViewById(R.id.text);
        text.setText(task.getString("task"));

        // checkbox
        final CheckBox checkBox = convertView.findViewById(R.id.checked);
        checkBox.setChecked(task.getBoolean("complete"));
        checkBox.setOnClickListener(view -> updateCheckedStatus(task.toMutable(), checkBox.isChecked()));

        return convertView;
    }

    private Query query() {
        return DAO.get().createQuery(
            SelectResult.expression(Meta.id),
            SelectResult.property("task"),
            SelectResult.property("complete"),
            SelectResult.property("image"))
            .where(Expression.property("type").equalTo(Expression.string("task"))
                .and(Expression.property("taskList.id").equalTo(Expression.string(listID))))
            .orderBy(Ordering.property("createdAt"), Ordering.property("task"));
    }

    private void updateCheckedStatus(MutableDocument task, boolean checked) {
        task.setBoolean("complete", checked);
        DAO.get().save(task);
    }
}
