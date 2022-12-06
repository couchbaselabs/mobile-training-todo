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
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import java.util.HashMap;
import java.util.Map;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.tasks.DeleteDocsByIdTask;
import com.couchbase.todo.tasks.FetchDocsByIdTask;
import com.couchbase.todo.tasks.SaveDocTask;
import com.couchbase.todo.ui.UsersAdapter;


public class UsersFragment extends Fragment {
    private static final String TAG = "FRAG_USERS";

    @Nullable
    private String listId;
    @Nullable
    private UsersAdapter adapter;

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        listId = ((ListDetailActivity) context).getListId();
    }

    @NonNull
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle state) {
        final View view = inflater.inflate(R.layout.fragment_users, container, false);

        final FloatingActionButton fab = view.findViewById(R.id.add_user);
        fab.setOnClickListener(v -> displayCreateDialog(inflater, listId));

        final ListView listView = view.findViewById(R.id.users_list);
        listView.setOnItemLongClickListener(this::handleLongClick);

        adapter = new UsersAdapter(view.getContext(), listId);
        listView.setAdapter(adapter);

        return view;
    }

    boolean handleLongClick(AdapterView<?> unused, @NonNull View view, int pos, long id) {
        final PopupMenu popup = new PopupMenu(getContext(), view);
        popup.inflate(R.menu.menu_user);
        popup.setOnMenuItemClickListener(item -> {
            handlePopupAction(item, adapter.getItem(pos));
            return true;
        });
        popup.show();
        return true;
    }

    void handlePopupAction(@NonNull MenuItem item, @NonNull String docId) {
        if (item.getItemId() == R.id.action_user_delete) {
            new DeleteDocsByIdTask(DatabaseService.COLLECTION_USERS).execute(docId);
        }
    }

    void displayCreateDialog(@NonNull LayoutInflater inflater, @NonNull String listId) {
        final View view = inflater.inflate(R.layout.view_dialog_input, null);

        final EditText input = view.findViewById(R.id.text);

        final AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_user));
        alert.setView(view);
        alert.setPositiveButton(
            R.string.ok,
            (dialog, whichButton) -> {
                final String title = input.getText().toString();
                if (TextUtils.isEmpty(title)) { return; }
                new FetchDocsByIdTask(DatabaseService.COLLECTION_LISTS, doc -> createUser(title, doc)).execute(listId);
            });
        alert.show();
    }

    // create task
    private void createUser(@NonNull String username, @NonNull Document taskList) {
        final Map<String, Object> taskListInfo = new HashMap<>();
        taskListInfo.put("id", listId);
        taskListInfo.put("owner", taskList.getString("owner"));

        final MutableDocument mDoc = new MutableDocument(listId + "." + username);
        mDoc.setString("username", username);
        mDoc.setValue("taskList", taskListInfo);

        new SaveDocTask(DatabaseService.COLLECTION_USERS).execute(mDoc);
    }
}
