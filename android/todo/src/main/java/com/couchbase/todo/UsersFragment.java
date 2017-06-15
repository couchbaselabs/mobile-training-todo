package com.couchbase.todo;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import com.couchbase.lite.Database;
import com.couchbase.lite.Document;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class UsersFragment extends Fragment {
    private ListView listView;
    private UsersAdapter adapter;

    private Database db;
    private Document taskList;

    public UsersFragment() {
    }

    @Override
    public View onCreateView(final LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_tasks, null);

        FloatingActionButton fab = view.findViewById(R.id.fab);
        fab.setOnClickListener(new android.view.View.OnClickListener() {
            @Override
            public void onClick(android.view.View view) {
                displayCreateDialog(inflater);
            }
        });

        db = ((Application) getActivity().getApplication()).getDatabase();
        taskList = db.getDocument(getActivity().getIntent().getStringExtra(ListsActivity.INTENT_LIST_ID));

        adapter = new UsersAdapter(this, db, taskList.getId(), new ArrayList<Document>());
        listView = view.findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener() {
            @Override
            public boolean onItemLongClick(AdapterView<?> parent, View view, final int pos, long id) {
                PopupMenu popup = new PopupMenu(getContext(), view);
                popup.inflate(R.menu.user_item);
                popup.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        handlePopupAction(item, adapter.getItem(pos));
                        return true;
                    }
                });
                popup.show();
                return true;
            }
        });

        adapter.reload();
        return view;
    }

    private void handlePopupAction(MenuItem item, Document doc) {
        switch (item.getItemId()) {
            case R.id.delete:
                delete(doc);
                return;
        }
    }

    private void displayCreateDialog(LayoutInflater inflater) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_user));
        final android.view.View view = inflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                String title = input.getText().toString();
                if (title.length() == 0)
                    return;
                createUser(title);
            }
        });
        alert.show();
    }

    // -------------------------
    // Database - CRUD
    // -------------------------

    // create task
    private void createUser(String username) {
        Document doc = new Document();
        doc.set("type", "task-list.user");
        doc.set("username", username);
        Map<String, Object> taskListInfo = new HashMap<String, Object>();
        taskListInfo.put("id", taskList.getId());
        taskListInfo.put("owner", taskList.getString("owner"));
        doc.set("taskList", taskListInfo);
        db.save(doc);
        adapter.reload();
    }

    private void delete(Document doc) {
        db.delete(doc);
        adapter.reload();
    }
}
