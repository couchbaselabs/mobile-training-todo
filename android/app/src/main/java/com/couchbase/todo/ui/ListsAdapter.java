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
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.R;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.db.FetchTask;


public class ListsAdapter extends ArrayAdapter<String> {
    private static final String TAG = "LISTS";


    private final Map<String, Integer> incompleteTaskCounts = new HashMap<>();

    private final Query incompleteTasksCountQuery;
    private final Query listsQuery;

    public ListsAdapter(@NonNull Context context) {
        super(context, 0);

        listsQuery = getListsQuery();
        DAO.get().addChangeListener(listsQuery, this::onListsChanged);

        incompleteTasksCountQuery = getIncompleteTasksCountQuery();
        DAO.get().addChangeListener(incompleteTasksCountQuery, this::onIncompleteTasksChanged);
    }

    @NonNull
    @Override
    public View getView(int position, @Nullable View convertView, @NonNull ViewGroup parent) {
        final View rootView = (convertView != null)
            ? convertView
            : LayoutInflater.from(getContext()).inflate(R.layout.view_list, parent, false);

        new FetchTask(docs -> populateView(rootView, docs.get(0))).execute(getItem(position));

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
        for (Result r : change.getResults()) { add(r.getString(0)); }
        notifyDataSetChanged();
    }

    void onIncompleteTasksChanged(@NonNull QueryChange change) {
        incompleteTaskCounts.clear();
        for (Result r : change.getResults()) {
            incompleteTaskCounts.put(r.getString(0), r.getInt(1));
        }
        notifyDataSetChanged();
    }

    private Query getListsQuery() {
        return DAO.get().createQuery(SelectResult.expression(Meta.id))
            .where(Expression.property("type").equalTo(Expression.string("task-list")))
            .orderBy(Ordering.property("name").ascending());
    }

    private Query getIncompleteTasksCountQuery() {
        final Expression exprTaskListId = Expression.property("taskList.id");
        return DAO.get().createQuery(
            SelectResult.expression(exprTaskListId),
            SelectResult.expression(Function.count(Expression.all())))
            .where(Expression.property("type").equalTo(Expression.string("task"))
                .and(Expression.property("complete").equalTo(Expression.booleanValue(false))))
            .groupBy(exprTaskListId);
    }
}
