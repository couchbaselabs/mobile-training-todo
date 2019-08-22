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

import android.os.AsyncTask;
import android.util.Log;
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
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryChange;
import com.couchbase.lite.Result;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.R;
import com.couchbase.todo.TasksFragment;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.db.FetchTask;
import com.couchbase.todo.db.SimpleConflictResolver;


public class TasksAdapter extends ArrayAdapter<String> {
    private static final String TAG = "TASKS";

    private static class UpdateCheckTask extends AsyncTask<Boolean, Void, Void> {
        private final String taskId;

        UpdateCheckTask(String taskId) { this.taskId = taskId; }

        @Override
        protected Void doInBackground(Boolean... args) {
            final Document doc = DAO.get().fetch(taskId);
            if (doc == null) {
                Log.w(TAG, "attempt to update non-existent document: " + taskId);
                return null;
            }

            final MutableDocument task = doc.toMutable();
            task.setBoolean("complete", args[0]);
            DAO.get().save(task);

            return null;
        }
    }

    private final TasksFragment fragment;
    private final String listID;

    private final Query query;

    public TasksAdapter(@NonNull TasksFragment fragment, @NonNull String listID) {
        super(fragment.getContext(), 0);

        this.fragment = fragment;
        this.listID = listID;

        this.query = getTasksQuery();
        DAO.get().addChangeListener(query, this::updateContent);
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        final View rootView = (convertView != null)
            ? convertView
            : LayoutInflater.from(getContext()).inflate(R.layout.view_task, parent, false);

        final String docID = getItem(position);
        new FetchTask(docs -> populateView(rootView, docs.get(0))).execute(docID);

        final ImageView imageView = rootView.findViewById(R.id.task_photo);
        imageView.setOnClickListener(v -> fragment.dispatchTakePhotoIntent(docID));

        final CheckBox checkBox = rootView.findViewById(R.id.task_completed);
        checkBox.setOnClickListener(view ->
            new UpdateCheckTask(docID).execute(checkBox.isChecked()));

        return rootView;
    }

    void populateView(View view, Document task) {
        final Blob thumbnail = task.getBlob("image");
        final ImageView imageView = view.findViewById(R.id.task_photo);
        if (thumbnail == null) { imageView.setImageResource(R.drawable.ic_camera_light); }
        else { Glide.with(getContext()).load(thumbnail.getContent()).into(imageView); }

        final TextView textView = view.findViewById(R.id.task_name);
        textView.setText(task.getString("task"));
        if (task.getString(SimpleConflictResolver.KEY_CONFLICT) != null) {
            textView.setTextColor(getContext().getColor(R.color.conflict));
        }

        final CheckBox checkBox = view.findViewById(R.id.task_completed);
        checkBox.setChecked(task.getBoolean("complete"));
    }

    void updateContent(QueryChange change) {
        clear();
        for (Result result : change.getResults()) { add(result.getString(0)); }
        notifyDataSetChanged();
    }

    private Query getTasksQuery() {
        return DAO.get().createQuery(
            SelectResult.expression(Meta.id),
            SelectResult.property("task"),
            SelectResult.property("complete"),
            SelectResult.property("image"))
            .where(Expression.property("type").equalTo(Expression.string("task"))
                .and(Expression.property("taskList.id").equalTo(Expression.string(listID))))
            .orderBy(Ordering.property("createdAt"), Ordering.property("task"));
    }
}
