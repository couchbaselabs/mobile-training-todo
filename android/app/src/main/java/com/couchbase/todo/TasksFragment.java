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

import android.app.AlertDialog;
import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
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

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.FileProvider;
import androidx.fragment.app.Fragment;

import java.io.File;
import java.io.IOException;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.tasks.AttachImageTask;
import com.couchbase.todo.tasks.CreateTaskTask;
import com.couchbase.todo.tasks.DeleteDocsByIdTask;
import com.couchbase.todo.tasks.FetchDocsByIdTask;
import com.couchbase.todo.tasks.SaveDocTask;
import com.couchbase.todo.tasks.TaskDumper;
import com.couchbase.todo.ui.TasksAdapter;


public class TasksFragment extends Fragment {
    private static final String TAG = "FRAG_TASKS";

    @Nullable
    private String listId;
    @Nullable
    private TasksAdapter adapter;
    @Nullable
    private ActivityResultLauncher<Uri> camera;
    @Nullable
    private String authority;

    @Nullable
    private String imageFilePath;
    @Nullable
    private String selectedTask;

    // -------------------------
    // Camera/Photo
    // -------------------------

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        listId = ((ListDetailActivity) context).getListId();

        authority = context.getPackageName() + ".provider";

        camera = registerForActivityResult(new ActivityResultContracts.TakePicture(), this::onPhoto);
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle state) {
        final View view = inflater.inflate(R.layout.fragment_tasks, container, false);

        final FloatingActionButton fab = view.findViewById(R.id.add_task);
        fab.setOnClickListener(v -> displayCreateDialog(inflater, listId));

        final ListView listView = view.findViewById(R.id.task_list);
        listView.setOnItemLongClickListener(this::handleLongClick);

        adapter = new TasksAdapter(this, listId);
        listView.setAdapter(adapter);

        return view;
    }

    boolean handleLongClick(AdapterView<?> unused, @NonNull View view, int pos, long id) {
        final PopupMenu popup = new PopupMenu(getContext(), view);
        popup.inflate(R.menu.menu_task);
        popup.setOnMenuItemClickListener(item -> {
            handlePopupAction(item, adapter.getItem(pos));
            return true;
        });
        popup.show();
        return true;
    }

    public void takePhoto(String taskId) {
        final Context context = getActivity();
        if (context == null) { return; }

        File imageFile = createImageFile(context);
        if (imageFile == null) { return; }

        try { imageFilePath = imageFile.getCanonicalPath(); }
        catch (IOException e) { return; }

        selectedTask = taskId;

        camera.launch(FileProvider.getUriForFile(context, authority, imageFile));
    }

    void handlePopupAction(@NonNull MenuItem item, @NonNull String taskId) {
        if (item.getItemId() == R.id.action_task_update) {
            new FetchDocsByIdTask(DatabaseService.COLLECTION_TASKS, this::displayUpdateTaskDialog).execute(taskId);
        }
        if (item.getItemId() == R.id.action_task_delete) {
            new DeleteDocsByIdTask(DatabaseService.COLLECTION_TASKS).execute(taskId);
        }
        if (item.getItemId() == R.id.action_task_dump) {
            new TaskDumper().execute(taskId);
        }
    }

    // display create task dialog
    void displayCreateDialog(@NonNull LayoutInflater inflater, @NonNull String listId) {
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
                new CreateTaskTask(listId).execute(title);
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
                new SaveDocTask(DatabaseService.COLLECTION_TASKS).execute(mDoc);
            });
        alert.show();
    }

    private void onPhoto(@NonNull Boolean ok) {
        final String imgPath = imageFilePath;
        imageFilePath = null;
        final String taskId = selectedTask;
        selectedTask = null;

        if (!ok) {
            Log.w(TAG, "Failed taking photo");
            return;
        }

        new AttachImageTask(imgPath).execute(taskId);
    }

    private File createImageFile(@NonNull Context activity) {
        try {
            final File dir = new File(activity.getExternalFilesDir(Environment.DIRECTORY_PICTURES), "pix");
            if (!dir.exists()) {
                if (!dir.mkdirs()) { throw new IOException("Cannot create directory: " + dir.getPath()); }
            }

            final String imgFileName = StringUtils.getUniqueName("TODO_LITE_PHOTO", 8);
            return File.createTempFile(imgFileName, ".jpg", dir);
        }
        catch (IOException e) {
            Log.w(TAG, "Failed creating photo file", e);
            return null;
        }
    }
}
