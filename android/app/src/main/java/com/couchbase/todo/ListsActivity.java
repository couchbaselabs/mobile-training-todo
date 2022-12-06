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
import androidx.annotation.Nullable;

import java.util.UUID;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.tasks.DeleteDocsByIdTask;
import com.couchbase.todo.tasks.FetchDocsByIdTask;
import com.couchbase.todo.tasks.ListDumper;
import com.couchbase.todo.tasks.SaveDocTask;
import com.couchbase.todo.ui.ListsAdapter;


public class ListsActivity extends ToDoActivity {
    private static final String TAG = "ACT_LIST";

    public static void start(@NonNull Activity act) {
        final Intent intent = new Intent(act, ListsActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        act.startActivity(intent);
    }


    @Nullable
    private ListsAdapter adapter;

    @Override
    protected void onCreateLoggedIn(@Nullable Bundle state) {
        setContentView(R.layout.activity_lists);

        findViewById(R.id.add_list).setOnClickListener(view -> displayCreateListDialog());

        adapter = new ListsAdapter(this);

        final ListView listView = findViewById(R.id.lists_list);
        listView.setAdapter(adapter);
        listView.setOnItemClickListener((adapterView, view, i, l) ->
            new FetchDocsByIdTask(DatabaseService.COLLECTION_LISTS, this::showTaskListView).execute(adapter.getItem(i)));
        listView.setOnItemLongClickListener(this::showPopup);
    }

    void showTaskListView(@NonNull Document doc) { ListDetailActivity.start(this, doc.getId()); }

    boolean showPopup(@NonNull AdapterView<?> parent, @NonNull View view, int pos, long id) {
        final PopupMenu popup = new PopupMenu(ListsActivity.this, view);
        popup.inflate(R.menu.menu_list);
        popup.setOnMenuItemClickListener(item -> handleListPopupAction(item, adapter.getItem(pos)));
        popup.show();
        return true;
    }

    boolean handleListPopupAction(@NonNull MenuItem item, @NonNull String docId) {
        final int itemId = item.getItemId();

        if (R.id.action_list_update == itemId) {
            new FetchDocsByIdTask(DatabaseService.COLLECTION_LISTS, this::displayUpdateListDialog).execute(docId);
            return true;
        }

        if (R.id.action_list_delete == itemId) {
            new DeleteDocsByIdTask(DatabaseService.COLLECTION_LISTS).execute(docId);
            return true;
        }

        if (R.id.action_list_dump == itemId) {
            new ListDumper().execute(docId);
            return true;
        }

        return false;
    }

    // display create list dialog
    void displayCreateListDialog() {
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
    void displayUpdateListDialog(@NonNull Document list) {
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
    void createList(@NonNull String title) {
        final String username = DatabaseService.get().getUsername();
        final String docId = username + "." + UUID.randomUUID();
        final MutableDocument mDoc = new MutableDocument(docId);
        mDoc.setString("name", title);
        mDoc.setString("owner", username);
        new SaveDocTask(DatabaseService.COLLECTION_LISTS).execute(mDoc);
    }

    // update list
    void updateList(@NonNull MutableDocument list, @NonNull String title) {
        list.setString("name", title);
        new SaveDocTask(DatabaseService.COLLECTION_LISTS).execute(list);
    }
}
