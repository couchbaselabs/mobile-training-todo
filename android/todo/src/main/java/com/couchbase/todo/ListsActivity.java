package com.couchbase.todo;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

import java.util.UUID;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;


public class ListsActivity extends AppCompatActivity {

    private static final String TAG = ListsActivity.class.getSimpleName();

    public static final String INTENT_LIST_ID = "list_id";

    private String username;
    private Database db;

    private ListView listView;
    private ListsAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_lists);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        toolbar.setTitle(getTitle());

        Application application = (Application) getApplication();
        username = application.getUsername();
        db = application.getDatabase();
        if (db == null) { throw new IllegalArgumentException(); }

        FloatingActionButton fab = findViewById(R.id.fab);
        fab.setOnClickListener(view -> displayCreateListDialog());

        adapter = new ListsAdapter(this, db);
        listView = findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemClickListener((adapterView, view, i, l) -> {
            String id = adapter.getItem(i);
            Document list = db.getDocument(id);
            showTaskListView(list);
        });
        listView.setOnItemLongClickListener((parent, view, pos, id) -> {
            PopupMenu popup = new PopupMenu(ListsActivity.this, view);
            popup.inflate(R.menu.list_item);
            popup.setOnMenuItemClickListener(item -> {
                String id1 = adapter.getItem(pos);
                Document list = db.getDocument(id1);
                return handleListPopupAction(item, list);
            });
            popup.show();
            return true;
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        // logout menu
        getMenuInflater().inflate(R.menu.logout_menu, menu);

        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == R.id.logout) {
            Application application = (Application) getApplication();
            application.logout();
            return true;
        }// If we got here, the user's action was not recognized.
        // Invoke the superclass to handle it.
        return super.onOptionsItemSelected(item);
    }

    private boolean handleListPopupAction(MenuItem item, Document list) {
        switch (item.getItemId()) {
            case R.id.update:
                displayUpdateListDialog(list);
                return true;
            case R.id.delete:
                deleteList(list);
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
    // Database - CRUD
    // -------------------------

    // create list
    private Document createList(String title) {
        String docId = username + "." + UUID.randomUUID();
        MutableDocument mDoc = new MutableDocument(docId);
        mDoc.setString("type", "task-list");
        mDoc.setString("name", title);
        mDoc.setString("owner", username);
        try {
            db.save(mDoc);
            return db.getDocument(mDoc.getId());
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to save the document", e);
            //TODO: Error handling
            return null;
        }
    }

    // update list
    private Document updateList(final MutableDocument list, String title) {
        list.setString("name", title);
        try {
            db.save(list);
            return db.getDocument(list.getId());
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to save the document", e);
            //TODO: Error handling
            return null;
        }
    }

    // delete list
    private Document deleteList(final Document list) {
        try {
            db.delete(list);
        }
        catch (CouchbaseLiteException e) {
            Log.e(TAG, "Failed to delete the document", e);
            //TODO: Error handling
        }
        return list;
    }
}
