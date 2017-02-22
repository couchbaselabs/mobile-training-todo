package com.couchbase.todo;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;
import android.widget.TextView;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Emitter;
import com.couchbase.lite.LiveQuery;
import com.couchbase.lite.Mapper;
import com.couchbase.lite.QueryEnumerator;
import com.couchbase.lite.QueryRow;
import com.couchbase.lite.Reducer;
import com.couchbase.lite.SavedRevision;
import com.couchbase.lite.UnsavedRevision;
import com.couchbase.lite.util.Log;
import com.couchbase.todo.util.LiveQueryAdapter;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class ListsActivity extends AppCompatActivity {

    private Database mDatabase;
    private String mUsername;
    private Map<String, Object> incompCounts;

    private LiveQuery listsLiveQuery = null;
    private LiveQuery incompTasksCountLiveQuery = null;
    private ListAdapter mAdapter;

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (listsLiveQuery != null) {
            listsLiveQuery.stop();
            listsLiveQuery = null;
        }
        if (incompTasksCountLiveQuery != null) {
            incompTasksCountLiveQuery.stop();
            incompTasksCountLiveQuery = null;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_lists);

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        toolbar.setTitle(getTitle());

        FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                displayCreateDialog();
            }
        });

        fab.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View v) {
                createListConflict();
                return true;
            }
        });

        Application application = (Application) getApplication();
        mDatabase = application.getDatabase();
        mUsername = application.getUsername();

        setupViewAndQuery();
        mAdapter = new ListAdapter(this, listsLiveQuery);

        ListView listView = (ListView) findViewById(R.id.list);
        listView.setAdapter(mAdapter);

        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                Document list = (Document) mAdapter.getItem(i);
                showTasks(list);
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
                        Document list = (Document) mAdapter.getItem(pos);
                        String owner = (String) list.getProperties().get("owner");
                        Application application = (Application) getApplication();
                        String moderatorDocId = "moderator." + application.getUsername();
                        if (owner == null || owner.equals(application.getUsername()))
                            handleListPopupAction(item, list);
                        else if (application.getDatabase().getExistingDocument(moderatorDocId) != null)
                            handleListPopupAction(item, list);
                        else
                            application.showErrorMessage("Only the owner or a moderator can update/delete the list", null);
                        return true;
                    }
                });
                popup.show();
                return true;
            }
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the logout_menu items for use in the action bar

        Bundle bundle = this.getIntent().getExtras();
        if(bundle != null) {
            Boolean loginFlowEnabled = bundle.getBoolean(Application.LOGIN_FLOW_ENABLED);
            if(loginFlowEnabled) {
                MenuInflater inflater = getMenuInflater();
                inflater.inflate(R.menu.logout_menu, menu);
            }
        }

        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.logout:
                Application application = (Application) getApplication();
                application.logout();
                return true;
            default:
                // If we got here, the user's action was not recognized.
                // Invoke the superclass to handle it.
                return super.onOptionsItemSelected(item);
        }
    }

    // Database

    private void setupViewAndQuery() {
        if (mDatabase == null) {
            return;
        }
        com.couchbase.lite.View listsView = mDatabase.getView("list/listsByName");
        if (listsView.getMap() == null) {
            listsView.setMap(new Mapper() {
                @Override
                public void map(Map<String, Object> document, Emitter emitter) {
                    String type = (String) document.get("type");
                    if ("task-list".equals(type)) {
                        emitter.emit(document.get("name"), null);
                    }
                }
            }, "1.0");
        }

        listsLiveQuery = listsView.createQuery().toLiveQuery();

        com.couchbase.lite.View incompTasksCountView = mDatabase.getView("list/incompleteTasksCount");
        if (incompTasksCountView.getMap() == null) {
            incompTasksCountView.setMapReduce(new Mapper() {
                @Override
                public void map(Map<String, Object> document, Emitter emitter) {
                    String type = (String) document.get("type");
                    if ("task".equals(type)) {
                        Boolean complete = (Boolean) document.get("complete");
                        if (!complete) {
                            Map<String, Object> taskList = (Map<String, Object>) document.get("taskList");
                            String listId = (String) taskList.get("id");
                            emitter.emit(listId, null);
                        }
                    }
                }
            }, new Reducer() {
                @Override
                public Object reduce(List<Object> keys, List<Object> values, boolean rereduce) {
                    return values.size();
                }
            }, "1.0");
        }

        incompTasksCountLiveQuery = incompTasksCountView.createQuery().toLiveQuery();
        incompTasksCountLiveQuery.setGroupLevel(1);

        final LiveQuery finalIncompTasksCountLiveQuery = incompTasksCountLiveQuery;
        incompTasksCountLiveQuery.addChangeListener(new LiveQuery.ChangeListener() {
            @Override
            public void changed(LiveQuery.ChangeEvent event) {
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Map<String, Object> counts = new HashMap<String, Object>();
                        QueryEnumerator rows = finalIncompTasksCountLiveQuery.getRows();
                        for (QueryRow row : rows) {
                            String listId = (String) row.getKey();
                            int count = (int) row.getValue();
                            counts.put(listId, count);
                        }
                        incompCounts = counts;
                        mAdapter.notifyDataSetChanged();
                    }
                });
            }
        });
        incompTasksCountLiveQuery.start();
    }

    private void handleListPopupAction(MenuItem item, Document list) {
        switch (item.getItemId()) {
            case R.id.update:
                updateList(list);
                return;
            case R.id.delete:
                deleteList(list);
                return;
        }
    }

    private void showTasks(Document list) {
        Intent intent = new Intent(this, ListDetailActivity.class);
        intent.putExtra(ListDetailActivity.INTENT_LIST_ID, list.getId());
        startActivity(intent);
    }

    private class ListAdapter extends LiveQueryAdapter {
        public ListAdapter(Context context, LiveQuery query) {
            super(context, query);
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            if (convertView == null) {
                LayoutInflater inflater = (LayoutInflater) parent.getContext().
                        getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                convertView = inflater.inflate(R.layout.view_list, null);
            }

            final Document list = (Document) getItem(position);
            String key = (String) getKey(position);
            TextView text = (TextView) convertView.findViewById(R.id.text);
            text.setText(key);


            TextView countText = (TextView) convertView.findViewById(R.id.task_count);
            if (incompCounts.get(list.getId()) != null) {
                countText.setText(String.valueOf(((int) incompCounts.get(list.getId()))));
            } else {
                countText.setText("");
            }

            return convertView;
        }

    }

    private void displayCreateDialog() {
        AlertDialog.Builder alert = new AlertDialog.Builder(this);
        alert.setTitle(getResources().getString(R.string.title_dialog_new_list));

        LayoutInflater inflater = this.getLayoutInflater();
        final View view = inflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = (EditText) view.findViewById(R.id.text);
        alert.setView(view);

        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                try {
                    String title = input.getText().toString();
                    if (title.length() == 0)
                        return;
                    createTaskList(title);
                } catch (CouchbaseLiteException e) {
                    Log.e(Application.TAG, "Cannot create a new list", e);
                }
            }
        });

        alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) { }
        });

        alert.show();
    }

    private void updateList(final Document list) {
        AlertDialog.Builder alert = new AlertDialog.Builder(this);
        alert.setTitle(getResources().getString(R.string.title_dialog_update));

        final EditText input = new EditText(this);
        input.setMaxLines(1);
        input.setSingleLine(true);
        String text = (String) list.getProperty("name");
        input.setText(text);
        alert.setView(input);
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                try {
                    list.update(new Document.DocumentUpdater() {
                        @Override
                        public boolean update(UnsavedRevision newRevision) {
                            Map<String, Object> props = newRevision.getUserProperties();
                            props.put("name", input.getText().toString());
                            newRevision.setUserProperties(props);
                            return true;
                        }
                    });
                } catch (CouchbaseLiteException e) {
                    e.printStackTrace();
                }
            }
        });
        alert.show();
    }

    private void deleteList(final Document list) {
        try {
            list.delete();
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    }

    private SavedRevision createTaskList(String title) throws CouchbaseLiteException {
        Map<String, Object> properties = new HashMap<String, Object>();
        properties.put("type", "task-list");
        properties.put("name", title);
        properties.put("owner", mUsername);

        String docId = mUsername + "." + UUID.randomUUID();

        Document document = mDatabase.getDocument(docId);
        return document.putProperties(properties);
    }

    private void createListConflict() {
        SavedRevision savedRevision = null;
        try {
            savedRevision = createTaskList("Test Conflicts List");
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        UnsavedRevision newRev1 = savedRevision.createRevision();
        Map<String, Object> propsRev1 = newRev1.getProperties();
        propsRev1.put("name", "Foosball");
        UnsavedRevision newRev2 = savedRevision.createRevision();
        Map<String, Object> propsRev2 = newRev2.getProperties();
        propsRev2.put("name", "Table Football");
        try {
            newRev1.save(true);
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        try {
            newRev2.save(true);
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    }

}
