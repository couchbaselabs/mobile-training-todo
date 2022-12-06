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

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryChange;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.R;
import com.couchbase.todo.TasksFragment;
import com.couchbase.todo.service.ConfigurableConflictResolver;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.tasks.FetchDocsByIdTask;
import com.couchbase.todo.tasks.UpdateTaskCompletedTask;


public class TasksAdapter extends ArrayAdapter<String> {
    private static final String TAG = "TASKS";

    private final TasksFragment fragment;
    private final String listID;

    private final Query query;

    public TasksAdapter(@NonNull TasksFragment fragment, @NonNull String listID) {
        super(fragment.getContext(), 0);

        this.fragment = fragment;
        this.listID = listID;

        this.query = getTasksQuery();
        DatabaseService.get().addQueryListener(query, this::updateContent);
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        final View rootView = (convertView != null)
            ? convertView
            : LayoutInflater.from(getContext()).inflate(R.layout.view_task, parent, false);

        final String docID = getItem(position);
        new FetchDocsByIdTask(DatabaseService.COLLECTION_TASKS, doc -> populateView(rootView, doc))
            .execute(docID);

        final ImageView imageView = rootView.findViewById(R.id.task_photo);
        imageView.setOnClickListener(v -> fragment.takePhoto(docID));

        final CheckBox checkBox = rootView.findViewById(R.id.task_completed);
        checkBox.setOnClickListener(view ->
            new UpdateTaskCompletedTask(docID).execute(checkBox.isChecked()));

        return rootView;
    }

    void populateView(View view, Document task) {
        final Blob thumbnail = task.getBlob("image");
        final ImageView imageView = view.findViewById(R.id.task_photo);
        if (thumbnail == null) { imageView.setImageResource(R.drawable.ic_camera_light); }
        else { Glide.with(getContext()).load(thumbnail.getContent()).into(imageView); }

        final TextView textView = view.findViewById(R.id.task_name);
        textView.setText(task.getString("task"));
        if (task.getString(ConfigurableConflictResolver.KEY_CONFLICT) != null) {
            textView.setTextColor(getContext().getColor(R.color.conflict));
        }

        final CheckBox checkBox = view.findViewById(R.id.task_completed);
        checkBox.setChecked(task.getBoolean("complete"));
    }

    void updateContent(QueryChange change) {
        clear();
        final ResultSet results = change.getResults();
        if (results == null) { return; }
        for (Result result: results) { add(result.getString(0)); }
        notifyDataSetChanged();
    }

    private Query getTasksQuery() {
        return DatabaseService.get().createQuery(
                DatabaseService.COLLECTION_TASKS,
                SelectResult.expression(Meta.id),
                SelectResult.property("task"),
                SelectResult.property("complete"),
                SelectResult.property("image"))
            .where(Expression.property("taskList.id").equalTo(Expression.string(listID)))
            .orderBy(Ordering.property("createdAt"), Ordering.property("task"));
    }
}
