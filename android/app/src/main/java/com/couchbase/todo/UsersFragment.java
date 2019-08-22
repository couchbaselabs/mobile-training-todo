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
import android.content.Context;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
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
import com.couchbase.todo.db.DeleteByIdTask;
import com.couchbase.todo.db.FetchTask;
import com.couchbase.todo.db.SaveTask;
import com.couchbase.todo.ui.UsersAdapter;


public class UsersFragment extends Fragment {
    private static final String TAG = "FRAG_USERS";


    private String listId;
    private UsersAdapter adapter;

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        listId = getDetailActivity().getListId();
    }

    @Override
    public View onCreateView(
        @NonNull LayoutInflater inflater,
        ViewGroup container,
        Bundle savedInstanceState) {
        final View view = inflater.inflate(R.layout.fragment_tasks, container, false);

        FloatingActionButton fab = view.findViewById(R.id.fab);
        fab.setOnClickListener(v -> displayCreateDialog(inflater, listId));

        ListView listView = view.findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemLongClickListener(this::handleLongClick);

        adapter = new UsersAdapter(getContext(), listId);
        listView.setAdapter(adapter);

        return view;
    }

    boolean handleLongClick(AdapterView unused, View view, int pos, long id) {
        PopupMenu popup = new PopupMenu(getContext(), view);
        popup.inflate(R.menu.menu_user);
        popup.setOnMenuItemClickListener(item -> {
            handlePopupAction(item, adapter.getItem(pos));
            return true;
        });
        popup.show();
        return true;
    }

    private void handlePopupAction(MenuItem item, String docId) {
        if (item.getItemId() == R.id.action_user_delete) {
            new DeleteByIdTask().execute(docId);
        }
    }

    private void displayCreateDialog(LayoutInflater inflater, String listId) {
        final View view = inflater.inflate(R.layout.view_dialog_input, null);

        final EditText input = view.findViewById(R.id.text);

        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_user));
        alert.setView(view);
        alert.setPositiveButton(
            R.string.ok,
            (dialog, whichButton) -> {
                String title = input.getText().toString();
                if (TextUtils.isEmpty(title)) { return; }
                new FetchTask(docs -> createUser(title, docs.get(0))).execute(listId);
            });
        alert.show();
    }

    // create task
    private void createUser(String username, Document taskList) {
        Map<String, Object> taskListInfo = new HashMap<>();
        taskListInfo.put("id", listId);
        taskListInfo.put("owner", taskList.getString("owner"));

        MutableDocument mDoc = new MutableDocument(listId + "." + username);
        mDoc.setString("type", "task-list.user");
        mDoc.setString("username", username);
        mDoc.setValue("taskList", taskListInfo);

        new SaveTask(null).execute(mDoc);
    }

    private ListDetailActivity getDetailActivity() { return (ListDetailActivity) getActivity(); }
}
