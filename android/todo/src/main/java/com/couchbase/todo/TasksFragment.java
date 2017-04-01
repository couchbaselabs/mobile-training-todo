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
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class TasksFragment extends Fragment {

    private ListView listView;
    private TasksAdapter adapter;

    private Database db;
    private Document taskList;

    public TasksFragment() {
    }

    @Override
    public View onCreateView(final LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_tasks, null);

        FloatingActionButton fab = (FloatingActionButton) view.findViewById(R.id.fab);
        fab.setOnClickListener(new android.view.View.OnClickListener() {
            @Override
            public void onClick(android.view.View view) {
                displayCreateTaskDialog(inflater);
            }
        });
        db = ((Application) getActivity().getApplication()).getDatabase();
        taskList = db.getDocument(getActivity().getIntent().getStringExtra(ListsActivity.INTENT_LIST_ID));

        adapter = new TasksAdapter(getContext(), db, taskList.getID(), new ArrayList<Document>());
        listView = (ListView) view.findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener() {
            @Override
            public boolean onItemLongClick(AdapterView<?> parent, View view, final int pos, long id) {
                PopupMenu popup = new PopupMenu(getContext(), view);
                popup.inflate(R.menu.list_item);
                popup.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        Document task = adapter.getItem(pos);
                        handleTaskPopupAction(item, task);
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


    private void handleTaskPopupAction(MenuItem item, Document task) {
        switch (item.getItemId()) {
            case R.id.update:
                displayUpdateTaskDialog(task);
                return;
            case R.id.delete:
                deleteTask(task);
                return;
        }
    }

    // display create task dialog
    private void displayCreateTaskDialog(LayoutInflater inflater) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_task));
        final android.view.View view = inflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = (EditText) view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                String title = input.getText().toString();
                if (title.length() == 0)
                    return;
                createTask(title);
            }
        });
        alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                // ignore
            }
        });
        alert.show();
    }

    private void displayUpdateTaskDialog(final Document task) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getContext());
        alert.setTitle(getResources().getString(R.string.title_dialog_update));

        final EditText input = new EditText(getContext());
        input.setMaxLines(1);
        input.setSingleLine(true);
        String text = task.getString("task");
        input.setText(text);
        alert.setView(input);
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                updateTask(task, input.getText().toString());
            }
        });
        alert.show();
    }

    // -------------------------
    // Database - CRUD
    // -------------------------

    // create task
    private void createTask(String title) {
        Document doc = db.getDocument();
        doc.set("type", "task");
        Map<String, Object> taskListInfo = new HashMap<String, Object>();
        taskListInfo.put("id", taskList.getID());
        taskListInfo.put("owner", taskList.getString("owner"));
        doc.set("taskList", taskListInfo);
        doc.set("createdAt", new Date());
        doc.set("task", title);
        doc.set("complete", false);
        doc.save();

        adapter.reload();
    }

    // update task
    private void updateTask(final Document task, String text) {
        task.set("task", text);
        task.save();

        adapter.reload();
    }

    // delete task
    private void deleteTask(final Document task) {
        task.delete();

        adapter.reload();
    }
}
