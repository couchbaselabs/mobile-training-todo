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

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import androidx.annotation.NonNull;

import java.util.List;
import java.util.UUID;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.db.DeleteByIdTask;
import com.couchbase.todo.db.FetchTask;
import com.couchbase.todo.db.SaveTask;
import com.couchbase.todo.ui.ListsAdapter;


public class ListsActivity extends ToDoActivity {
    private static final String TAG = "ACT_LIST";

    public static void start(@NonNull Activity act) {
        final Intent intent = new Intent(act, ListsActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        act.startActivity(intent);
    }


    private ListView listView;
    private ListsAdapter adapter;

    @Override
    protected void onCreateLoggedIn(Bundle state) {
        setContentView(R.layout.activity_lists);

        final FloatingActionButton fab = findViewById(R.id.add_list);
        fab.setOnClickListener(view -> displayCreateListDialog());

        adapter = new ListsAdapter(this);
        listView = findViewById(R.id.lists_list);
        listView.setAdapter(adapter);
        listView.setOnItemClickListener((adapterView, view, i, l) -> new FetchTask(this::showTaskListView).execute(adapter.getItem(i)));
        listView.setOnItemLongClickListener(this::showPopup);
    }

    private void showTaskListView(List<Document> docs) {
        ListDetailActivity.start(this, docs.get(0).getId());
    }

    private boolean showPopup(AdapterView<?> parent, View view, int pos, long id) {
        final PopupMenu popup = new PopupMenu(ListsActivity.this, view);
        popup.inflate(R.menu.menu_list);
        popup.setOnMenuItemClickListener(item -> handleListPopupAction(item, adapter.getItem(pos)));
        popup.show();
        return true;
    }

    private boolean handleListPopupAction(MenuItem item, String docId) {
        switch (item.getItemId()) {
            case R.id.action_list_update:
                new FetchTask(this::displayUpdateListDialog).execute(docId);
                return true;
            case R.id.action_list_delete:
                new DeleteByIdTask().execute(docId);
                return true;
            default:
                return false;
        }
    }

    // display create list dialog
    private void displayCreateListDialog() {
        final AlertDialog.Builder alert = new AlertDialog.Builder(this);
        alert.setTitle(getResources().getString(R.string.title_dialog_new_list));
        final View view = LayoutInflater.from(ListsActivity.this)
            .inflate(R.layout.view_dialog_input, null);
        final EditText input = view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", (dialog, whichButton) -> {
            final String title = input.getText().toString();
            if (TextUtils.isEmpty(title)) { return; }
            createList(title);
        });
        alert.setNegativeButton("Cancel", (dialog, whichButton) -> { });
        alert.show();
    }

    // display update list dialog
    private void displayUpdateListDialog(List<Document> docs) {
        final Document list = docs.get(0);

        final EditText input = new EditText(this);
        input.setMaxLines(1);
        input.setSingleLine(true);
        input.setText(list.getString("name"));

        final AlertDialog.Builder alert = new AlertDialog.Builder(this);
        alert.setTitle(getResources().getString(R.string.title_dialog_update));
        alert.setView(input);
        alert.setPositiveButton("Ok", (dialogInterface, i) -> {
            final String title = input.getText().toString();
            if (TextUtils.isEmpty(title)) { return; }
            updateList(list.toMutable(), title);
        });
        alert.show();
    }

    // -------------------------
    // DAO - CRUD
    // -------------------------

    // create list
    private void createList(String title) {
        final String username = DAO.get().getUsername();
        final String docId = username + "." + UUID.randomUUID();
        final MutableDocument mDoc = new MutableDocument(docId);
        mDoc.setString("type", "task-list");
        mDoc.setString("name", title);
        mDoc.setString("owner", username);
        new SaveTask(null).execute(mDoc);
    }

    // update list
    private void updateList(final MutableDocument list, String title) {
        list.setString("name", title);
        new SaveTask(null).execute(list);
    }
}
