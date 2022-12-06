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

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Function;
import com.couchbase.lite.Meta;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryChange;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.R;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.tasks.FetchDocsByIdTask;


public class ListsAdapter extends ArrayAdapter<String> {
    private static final String TAG = "LISTS";


    private final Map<String, Integer> incompleteTaskCounts = new HashMap<>();

    private final Query incompleteTasksCountQuery;
    private final Query listsQuery;

    public ListsAdapter(@NonNull Context context) {
        super(context, 0);

        listsQuery = getListsQuery();
        DatabaseService.get().addQueryListener(listsQuery, this::onListsChanged);

        incompleteTasksCountQuery = getIncompleteTasksCountQuery();
        DatabaseService.get().addQueryListener(incompleteTasksCountQuery, this::onIncompleteTasksChanged);
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        final View rootView = (convertView != null)
            ? convertView
            : LayoutInflater.from(getContext()).inflate(R.layout.view_list, parent, false);

        new FetchDocsByIdTask(DatabaseService.COLLECTION_LISTS, doc -> populateView(rootView, doc))
            .execute(getItem(position));

        return rootView;
    }

    void populateView(View view, Document list) {
        final TextView textView = view.findViewById(R.id.list_name);
        textView.setText(list.getString("name"));

        final Integer listId = incompleteTaskCounts.get(list.getId());
        final TextView countText = view.findViewById(R.id.task_count);
        countText.setText((listId == null) ? "" : String.valueOf(listId));
    }

    void onListsChanged(@NonNull QueryChange change) {
        clear();
        final ResultSet results = change.getResults();
        if (results == null) { return; }
        for (Result r: results) { add(r.getString(0)); }
        notifyDataSetChanged();
    }

    void onIncompleteTasksChanged(@NonNull QueryChange change) {
        incompleteTaskCounts.clear();
        final ResultSet results = change.getResults();
        if (results == null) { return; }
        for (Result r: results) {
            incompleteTaskCounts.put(r.getString(0), r.getInt(1));
        }
        notifyDataSetChanged();
    }

    private Query getListsQuery() {
        return DatabaseService.get().createQuery(
                DatabaseService.COLLECTION_LISTS,
                SelectResult.expression(Meta.id))
            .orderBy(Ordering.property("name").ascending());
    }

    private Query getIncompleteTasksCountQuery() {
        final Expression exprTaskListId = Expression.property("taskList.id");
        return DatabaseService.get().createQuery(
                DatabaseService.COLLECTION_TASKS,
                SelectResult.expression(exprTaskListId),
                SelectResult.expression(Function.count(Expression.all())))
            .where(Expression.property("complete").equalTo(Expression.booleanValue(false)))
            .groupBy(exprTaskListId);
    }
}
