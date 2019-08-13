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

import androidx.annotation.NonNull;


public class ListsAdapter extends ArrayAdapter<String> {
    private static final String TAG = ListsAdapter.class.getSimpleName();

    private final Map<String, Integer> incompCounts = new HashMap<>();

    private final Query incompTasksCountQuery;
    private final Query listsQuery;

    public ListsAdapter(Context context) {
        super(context, 0);

        listsQuery = listsQuery();
        DAO.get().addChangeListener(listsQuery, this::onListsChanged);

        incompTasksCountQuery = incompTasksCountQuery();
        DAO.get().addChangeListener(incompTasksCountQuery, this::onIncompTasksChanged);
    }

    @NonNull
    @Override
    public View getView(int position, View convertView, @NonNull ViewGroup parent) {
        if (convertView == null) {
            convertView = LayoutInflater.from(getContext()).inflate(R.layout.view_list, parent, false);
        }

        Document list = DAO.get().fetchDocument(getItem(position));

        TextView text = convertView.findViewById(R.id.text);
        text.setText(list.getString("name"));

        TextView countText = convertView.findViewById(R.id.task_count);
        Integer listId = incompCounts.get(list.getId());
        countText.setText((listId == null) ? "" : String.valueOf(listId));

        return convertView;
    }

    void onIncompTasksChanged(QueryChange change) {
        incompCounts.clear();
        for (Result r: change.getResults()) { incompCounts.put(r.getString(0), r.getInt(1)); }
        notifyDataSetChanged();
    }

    void onListsChanged(QueryChange change) {
        clear();
        for (Result r: change.getResults()) { add(r.getString(0)); }
        notifyDataSetChanged();
    }

    private Query listsQuery() {
        return DAO.get().createQuery(SelectResult.expression(Meta.id))
            .where(Expression.property("type").equalTo(Expression.string("task-list")))
            .orderBy(Ordering.property("name").ascending());
    }

    private Query incompTasksCountQuery() {
        Expression exprTaskListId = Expression.property("taskList.id");
        return DAO.get().createQuery(
            SelectResult.expression(exprTaskListId),
            SelectResult.expression(Function.count(Expression.all())))
            .where(Expression.property("type").equalTo(Expression.string("task"))
                .and(Expression.property("complete").equalTo(Expression.booleanValue(false))))
            .groupBy(exprTaskListId);
    }
}