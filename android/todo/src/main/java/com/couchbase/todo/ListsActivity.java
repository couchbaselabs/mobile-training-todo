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
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import java.util.UUID;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.ui.ListsAdapter;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import androidx.appcompat.widget.Toolbar;


public class ListsActivity extends ToDoActivity {
    private static final String TAG = ListsActivity.class.getSimpleName();

    public static final String INTENT_LIST_ID = "list_id";

    public static void start(Activity act, int flags) {
        Intent intent = new Intent(act, ListsActivity.class);
        intent.setFlags(flags | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        act.startActivity(intent);
    }


    private ListView listView;
    private ListsAdapter adapter;

    @Override
    protected void onCreateLoggedIn(Bundle state) {
        setContentView(R.layout.activity_lists);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        toolbar.setTitle(getTitle());

        FloatingActionButton fab = findViewById(R.id.fab);
        fab.setOnClickListener(view -> displayCreateListDialog());

        adapter = new ListsAdapter(this);
        listView = findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemClickListener((adapterView, view, i, l) -> {
            String id = adapter.getItem(i);
            Document list = DAO.get().fetchDocument(id);
            showTaskListView(list);
        });
        listView.setOnItemLongClickListener(this::showPopup);
    }

    private boolean showPopup(AdapterView<?> parent, View view, int pos, long id) {
        PopupMenu popup = new PopupMenu(ListsActivity.this, view);
        popup.inflate(R.menu.menu_list);
        popup.setOnMenuItemClickListener(item -> {
            String id1 = adapter.getItem(pos);
            Document list = DAO.get().fetchDocument(id1);
            return handleListPopupAction(item, list);
        });
        popup.show();
        return true;
    }

    private boolean handleListPopupAction(MenuItem item, Document list) {
        switch (item.getItemId()) {
            case R.id.action_update:
                displayUpdateListDialog(list);
                return true;
            case R.id.action_delete:
                DAO.get().delete(list);
                return true;
            default:
                return false;
        }
    }

    private void showTaskListView(Document list) {
        Intent intent = new Intent(this, ListDetailActivity.class);
        intent.putExtra(INTENT_LIST_ID, list.getId());
        startActivity(intent);
    }

    // display create list dialog
    private void displayCreateListDialog() {
        AlertDialog.Builder alert = new AlertDialog.Builder(this);
        alert.setTitle(getResources().getString(R.string.title_dialog_new_list));
        final View view = LayoutInflater.from(ListsActivity.this).inflate(R.layout.view_dialog_input, null);
        final EditText input = view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", (dialog, whichButton) -> {
            String title = input.getText().toString();
            if (title.length() == 0) { return; }
            createList(title);
        });
        alert.setNegativeButton("Cancel", (dialog, whichButton) -> { });
        alert.show();
    }

    // display update list dialog
    private void displayUpdateListDialog(final Document list) {
        AlertDialog.Builder alert = new AlertDialog.Builder(this);
        alert.setTitle(getResources().getString(R.string.title_dialog_update));
        final EditText input = new EditText(this);
        input.setMaxLines(1);
        input.setSingleLine(true);
        input.setText(list.getString("name"));
        alert.setView(input);
        alert.setPositiveButton("Ok", (dialogInterface, i) -> {
            String title = input.getText().toString();
            if (title.length() == 0) { return; }
            updateList(list.toMutable(), title);
        });
        alert.show();
    }

    // -------------------------
    // DAO - CRUD
    // -------------------------

    // create list
    private void createList(String title) {
        String username = DAO.get().getUsername();
        String docId = username + "." + UUID.randomUUID();
        MutableDocument mDoc = new MutableDocument(docId);
        mDoc.setString("type", "task-list");
        mDoc.setString("name", title);
        mDoc.setString("owner", username);
        DAO.get().save(mDoc);
    }

    // update list
    private void updateList(final MutableDocument list, String title) {
        list.setString("name", title);
        DAO.get().save(list);
    }
}
