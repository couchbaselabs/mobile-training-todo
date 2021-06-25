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
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;
import androidx.fragment.app.Fragment;

import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.db.DeleteByIdTask;
import com.couchbase.todo.db.FetchTask;
import com.couchbase.todo.db.SaveTask;
import com.couchbase.todo.pix.AttachImageTask;
import com.couchbase.todo.ui.TasksAdapter;


public class TasksFragment extends Fragment {
    private static final String TAG = "FRAG_TASKS";

    private static final int REQUEST_TAKE_PHOTO = 1;
    private static final int REQUEST_CHOOSE_PHOTO = 2;

    private static class CreateTaskTask extends AsyncTask<String, Void, Void> {
        private final String parentId;

        CreateTaskTask(String parentId) { this.parentId = parentId; }

        @Override
        protected Void doInBackground(String... args) {
            final String title = args[0];

            final Document taskList = DAO.get().fetch(parentId);

            final Map<String, Object> taskListInfo = new HashMap<>();
            taskListInfo.put("id", parentId);
            taskListInfo.put("owner", taskList.getString("owner"));

            final MutableDocument mDoc = new MutableDocument();
            mDoc.setString("type", "task");
            mDoc.setValue("taskList", taskListInfo);
            mDoc.setDate("createdAt", new Date());
            mDoc.setString("task", title);
            mDoc.setBoolean("complete", false);

            DAO.get().save(mDoc);

            return null;
        }
    }

    private final DateFormat dateFormatter = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US);

    private String listId;
    private TasksAdapter adapter;

    private String imageToBeAttachedPath;
    private String selectedTask;

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        listId = getDetailActivity().getListId();
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if ((resultCode != Activity.RESULT_OK) || (requestCode != REQUEST_TAKE_PHOTO)) { return; }
        new AttachImageTask().execute(selectedTask, imageToBeAttachedPath);
    }

    // -------------------------
    // Camera/Photo
    // -------------------------
    public void dispatchTakePhotoIntent(String taskId) {
        this.selectedTask = taskId;

        final Context ctxt = getContext();

        final Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(ctxt.getPackageManager()) == null) { return; }

        final File photoFile;
        try {
            photoFile = createImageFile();
            imageToBeAttachedPath = photoFile.getAbsolutePath();
        }
        catch (IOException e) {
            Log.w(TAG, "Failed creating photo file", e);
            return;
        }

        final Uri photoUri = FileProvider.getUriForFile(
            ctxt,
            ctxt.getApplicationContext().getPackageName() + ".provider",
            photoFile);

        takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri);

        startActivityForResult(takePictureIntent, REQUEST_TAKE_PHOTO);
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle state) {
        final View view = inflater.inflate(R.layout.fragment_tasks, container, false);

        listId = getDetailActivity().getListId();

        final FloatingActionButton fab = view.findViewById(R.id.add_task);
        fab.setOnClickListener(v -> displayCreateDialog(inflater, listId));

        final ListView listView = view.findViewById(R.id.task_list);
        listView.setOnItemLongClickListener(this::handleLongClick);

        adapter = new TasksAdapter(this, listId);
        listView.setAdapter(adapter);

        return view;
    }

    boolean handleLongClick(AdapterView<?> unused, View view, int pos, long id) {
        final PopupMenu popup = new PopupMenu(getContext(), view);
        popup.inflate(R.menu.menu_task);
        popup.setOnMenuItemClickListener(item -> {
            handlePopupAction(item, adapter.getItem(pos));
            return true;
        });
        popup.show();
        return true;
    }

    void handlePopupAction(MenuItem item, String taskId) {
        if (item.getItemId() == R.id.action_task_update) {
            new FetchTask(docs -> displayUpdateTaskDialog(docs.get(0))).execute(taskId);
        }
        if (item.getItemId() == R.id.action_task_delete) {
            new DeleteByIdTask().execute(taskId);
        }
    }

    // display create task dialog
    void displayCreateDialog(LayoutInflater inflater, String parentId) {
        final View view = inflater.inflate(R.layout.view_dialog_input, null);

        final EditText input = view.findViewById(R.id.text);

        final AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_task));
        alert.setView(view);
        alert.setPositiveButton(
            R.string.ok,
            (dialog, whichButton) -> {
                final String title = input.getText().toString();
                if (TextUtils.isEmpty(title)) { return; }
                new CreateTaskTask(parentId).execute(title);
            });
        alert.show();
    }

    void displayUpdateTaskDialog(Document task) {
        final AlertDialog.Builder alert = new AlertDialog.Builder(getContext());
        alert.setTitle(getResources().getString(R.string.title_dialog_update));

        final EditText input = new EditText(getContext());
        input.setMaxLines(1);
        input.setSingleLine(true);
        input.setText(task.getString("task"));

        alert.setView(input);
        alert.setPositiveButton(
            "Ok",
            (dialogInterface, i) -> {
                final MutableDocument mDoc = task.toMutable();
                mDoc.setString("task", input.getText().toString());
                new SaveTask(null).execute(mDoc);
            });
        alert.show();
    }

    private File createImageFile() throws IOException {
        final String imgFileName = "TODO_LITE-" + dateFormatter.format(new Date());
        final File storageDir = getActivity().getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        return File.createTempFile(imgFileName, ".jpg", storageDir);
    }

    private ListDetailActivity getDetailActivity() { return (ListDetailActivity) getActivity(); }
}
