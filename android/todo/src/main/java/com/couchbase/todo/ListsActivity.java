package com.couchbase.todo;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import com.couchbase.lite.Database;
import com.couchbase.lite.Document;

import java.util.ArrayList;
import java.util.UUID;

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

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        toolbar.setTitle(getTitle());

        Application application = (Application) getApplication();
        db = ((Application) getApplication()).getDatabase();
        username = application.getUsername();

        FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                displayCreateListDialog();
            }
        });

        adapter = new ListsAdapter(this, db, new ArrayList<Document>());
        listView = (ListView) findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                Document list = adapter.getItem(i);
                showTaskListView(list);
            }
        });
        listView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener() {
            @Override
            public boolean onItemLongClick(AdapterView<?> parent, View view, final int pos, long id) {
                PopupMenu popup = new PopupMenu(ListsActivity.this, view);
                popup.inflate(R.menu.list_item);
                popup.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        Document list = adapter.getItem(pos);
                        return handleListPopupAction(item, list);
                    }
                });
                popup.show();
                return true;
            }
        });
        adapter.reload();
    }

    private boolean handleListPopupAction(MenuItem item, Document list) {
        switch (item.getItemId()) {
            case R.id.update:
                displayUpdateListDialog(list);
                return true;
            case R.id.delete:
                deleteList(list);
                // refresh UI
                adapter.reload();
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
        final EditText input = (EditText) view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                String title = input.getText().toString();
                if (title.length() == 0)
                    return;
                createList(title);

            }
        });
        alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
            }
        });
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
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                String title = input.getText().toString();
                if (title.length() == 0)
                    return;
                updateList(list, title);
            }
        });
        alert.show();
    }

    // -------------------------
    // Database - CRUD
    // -------------------------

    // create list
    private Document createList(String title) {
        String docId = username + "." + UUID.randomUUID();
        Document doc = new Document(docId);
        doc.set("type", "task-list");
        doc.set("name", title);
        doc.set("owner", username);
        db.save(doc);

        // update UI
        adapter.reload();

        return doc;
    }

    // update list
    private Document updateList(final Document list, String title) {
        list.set("name", title);
        db.save(list);

        // update UI
        adapter.reload();

        return list;
    }

    // delete list
    private Document deleteList(final Document list) {
        db.delete(list);

        // update UI
        adapter.reload();

        return list;
    }
}
