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
package com.couchbase.todo;

import android.app.AlertDialog;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import java.util.HashMap;
import java.util.Map;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.ui.UsersAdapter;


public class UsersFragment extends Fragment {

    private static final String TAG = UsersFragment.class.getSimpleName();

    private ListView listView;
    private UsersAdapter adapter;

    private Document taskList;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_tasks, container, false);

        FloatingActionButton fab = view.findViewById(R.id.fab);
        fab.setOnClickListener(view12 -> displayCreateDialog(inflater));

        taskList = DAO.get().fetchDocument(getActivity().getIntent().getStringExtra(ListsActivity.INTENT_LIST_ID));

        adapter = new UsersAdapter(this.getContext(), taskList.getId());
        listView = view.findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemLongClickListener((parent, view1, pos, id) -> {
            PopupMenu popup = new PopupMenu(getContext(), view1);
            popup.inflate(R.menu.menu_user);
            popup.setOnMenuItemClickListener(item -> {
                handlePopupAction(item, DAO.get().fetchDocument(adapter.getItem(pos)));
                return true;
            });
            popup.show();
            return true;
        });

        return view;
    }

    private void handlePopupAction(MenuItem item, Document doc) {
        if (item.getItemId() == R.id.action_delete) {
            DAO.get().delete(doc);
        }
    }

    private void displayCreateDialog(LayoutInflater inflater) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_user));
        final View view = inflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", (dialog, whichButton) -> {
            String title = input.getText().toString();
            if (title.length() == 0) { return; }
            createUser(title);
        });
        alert.show();
    }

    // -------------------------
    // DAO - CRUD
    // -------------------------

    // create task
    private void createUser(String username) {
        String docId = taskList.getId() + "." + username;
        MutableDocument mDoc = new MutableDocument(docId);
        mDoc.setString("type", "task-list.user");
        mDoc.setString("username", username);
        Map<String, Object> taskListInfo = new HashMap<>();
        taskListInfo.put("id", taskList.getId());
        taskListInfo.put("owner", taskList.getString("owner"));
        mDoc.setValue("taskList", taskListInfo);
        DAO.get().save(mDoc);
    }
}
