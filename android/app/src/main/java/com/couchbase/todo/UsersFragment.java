package com.couchbase.todo;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
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
import android.widget.TextView;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Emitter;
import com.couchbase.lite.LiveQuery;
import com.couchbase.lite.Mapper;
import com.couchbase.lite.Query;
import com.couchbase.lite.UnsavedRevision;
import com.couchbase.lite.util.Log;
import com.couchbase.todo.util.LiveQueryAdapter;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import static com.couchbase.todo.ListDetailActivity.INTENT_LIST_ID;

public class UsersFragment extends Fragment {
    private LayoutInflater mInflater;
    private ListView mListView;

    private Database mDatabase;
    private String mUsername;
    public Document mTaskList;
    LiveQuery usersLiveQuery = null;

    public UsersFragment() {
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (usersLiveQuery != null) {
            usersLiveQuery.stop();
            usersLiveQuery = null;
        }
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        mInflater = inflater;

        View main = inflater.inflate(R.layout.fragment_users, null);

        mListView = (ListView) main.findViewById(R.id.users_list);
        FloatingActionButton fab = (FloatingActionButton) main.findViewById(R.id.add_user);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                displayCreateDialog();
            }
        });

        Application application = (Application) getActivity().getApplication();
        mDatabase = application.getDatabase();
        mUsername = application.getUsername();
        Intent intent = getActivity().getIntent();
        mTaskList = mDatabase.getDocument(intent.getStringExtra(INTENT_LIST_ID));

        setupViewAndQuery();

        return main;
    }

    // Database

    private void setupViewAndQuery() {
        com.couchbase.lite.View view = mDatabase.getView("usersByUsername");
        if (view.getMap() == null) {
            view.setMap(new Mapper() {
                @Override
                public void map(Map<String, Object> document, Emitter emitter) {
                    String type = (String) document.get("type");
                    if ("task-list.user".equals(type)) {
                        Map<String, Object> taskList = (Map<String, Object>) document.get("taskList");
                        String listId = (String) taskList.get("id");
                        String username = (String) document.get("username");
                        ArrayList<String> key = new ArrayList<String>();
                        key.add(listId);
                        key.add(username);
                        emitter.emit(key, null);
                    }
                }
            }, "1.0");
        }

        Query query = view.createQuery();

        usersLiveQuery = query.toLiveQuery();
        ArrayList<String> startKey = new ArrayList<String>();
        startKey.add(mTaskList.getId());
        usersLiveQuery.setStartKey(startKey);
        usersLiveQuery.setEndKey(startKey);
        usersLiveQuery.setPrefixMatchLevel(1);

        final UsersFragment.UserAdapter mAdapter = new UsersFragment.UserAdapter(getActivity(), usersLiveQuery);

        mListView.setAdapter(mAdapter);

        mListView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener() {
            @Override
            public boolean onItemLongClick(AdapterView<?> parent, View view, final int pos, long id) {
                PopupMenu popup = new PopupMenu(getContext(), view);
                popup.inflate(R.menu.user_item);
                popup.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        Document user = (Document) mAdapter.getItem(pos);
                        deleteUser(user);
                        return true;
                    }
                });
                popup.show();
                return true;
            }
        });
    }

    private void deleteUser(final Document user) {
        try {
            user.update(new Document.DocumentUpdater() {
                @Override
                public boolean update(UnsavedRevision newRevision) {
                    Map<String, Object> props = newRevision.getProperties();
                    props.put("_deleted", true);
                    newRevision.setProperties(props);
                    return true;
                }
            });
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    }

    private void displayCreateDialog() {
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_user));

        final android.view.View view = mInflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = (EditText) view.findViewById(R.id.text);
        alert.setView(view);

        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                try {
                    String title = input.getText().toString();
                    if (title.length() == 0)
                        return;
                    createUser(title);
                } catch (CouchbaseLiteException e) {
                    Log.e(Application.TAG, "Cannot invite new user", e);
                }
            }
        });

        alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) { }
        });

        alert.show();
    }

    private Document createUser(String username) throws CouchbaseLiteException {
        Map<String, Object> taskListInfo = new HashMap<String, Object>();
        taskListInfo.put("id", mTaskList.getId());
        taskListInfo.put("owner", mTaskList.getProperty("owner"));

        Map<String, Object> properties = new HashMap<String, Object>();
        properties.put("type", "task-list.user");
        properties.put("taskList", taskListInfo);
        properties.put("username", username);

        String docId = mTaskList.getId() + "." + username;

        Document document = mDatabase.getDocument(docId);
        document.putProperties(properties);
        return document;
    }

    private class UserAdapter extends LiveQueryAdapter {

        public UserAdapter(Context context, LiveQuery query) {
            super(context, query);
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            if (convertView == null) {
                LayoutInflater inflater = (LayoutInflater) parent.getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                convertView = inflater.inflate(R.layout.view_user, null);
            }

            final Document user = (Document) getItem(position);
            if (user == null || user.getCurrentRevision() == null) {
                return convertView;
            }

            TextView userText = (TextView) convertView.findViewById(R.id.user_name);
            userText.setText((String) user.getProperty("username"));

            return convertView;
        }
    }

}
