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
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.db.DeleteByIdTask;
import com.couchbase.todo.db.DeleteTask;
import com.couchbase.todo.db.FetchTask;
import com.couchbase.todo.db.SaveTask;
import com.couchbase.todo.ui.TasksAdapter;

import static android.app.Activity.RESULT_OK;


public class TasksFragment extends Fragment {
    private static final String TAG = "FRAG_TASKS";

    private static final int REQUEST_TAKE_PHOTO = 1;
    private static final int REQUEST_CHOOSE_PHOTO = 2;
    private static final int THUMBNAIL_SIZE = 150;


    private static class CreateTaskTask extends AsyncTask<String, Void, Void> {
        private final String parentId;

        public CreateTaskTask(String parentId) { this.parentId = parentId; }

        @Override
        protected Void doInBackground(String... args) {
            final String title = args[0];

            Document taskList = DAO.get().fetch(parentId);

            Map<String, Object> taskListInfo = new HashMap<>();
            taskListInfo.put("id", parentId);
            taskListInfo.put("owner", taskList.getString("owner"));

            MutableDocument mDoc = new MutableDocument();
            mDoc.setString("type", "task");
            mDoc.setValue("taskList", taskListInfo);
            mDoc.setDate("createdAt", new Date());
            mDoc.setString("task", title);
            mDoc.setBoolean("complete", false);

            DAO.get().save(mDoc);

            return null;
        }
    }

    private static class AttachImageTask extends AsyncTask<String, Void, Void> {
        @Override
        protected Void doInBackground(String... args) {
            final String taskId = args[0];
            final String imagePath = args[1];

            final File imageFile = new File(imagePath);
            if (!imageFile.exists()) { return null; }

            Document task = DAO.get().fetch(taskId);
            if (task == null) { return null; }

            BitmapFactory.Options options = new BitmapFactory.Options();

            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(imagePath, options);

            options.inJustDecodeBounds = false;
            Bitmap image = BitmapFactory.decodeFile(imagePath, options);

            Bitmap thumbnail = ThumbnailUtils.extractThumbnail(image, THUMBNAIL_SIZE, THUMBNAIL_SIZE);

            imageFile.delete();

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            image.compress(Bitmap.CompressFormat.JPEG, 50, out);
            ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());

            final Blob blob = new Blob("image/jpg", in);

            final MutableDocument mutableTask = task.toMutable();
            mutableTask.setBlob("image", blob);

            DAO.get().save(mutableTask);

            return null;
        }
    }

    private final DateFormat dateFormatter = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US);

    private String listId;
    private TasksAdapter adapter;

    private String imageToBeAttachedPath;
    private String selectedTask;

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        listId = getDetailActivity().getListId();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_tasks, container, false);

        listId = getDetailActivity().getListId();

        FloatingActionButton fab = view.findViewById(R.id.fab);
        fab.setOnClickListener(v -> displayCreateDialog(inflater, listId));

        ListView listView = view.findViewById(R.id.list);
        listView.setOnItemLongClickListener(this::handleLongClick);

        adapter = new TasksAdapter(this, listId);
        listView.setAdapter(adapter);

        return view;
    }

    boolean handleLongClick(AdapterView unused, View view, int pos, long id) {
        PopupMenu popup = new PopupMenu(getContext(), view);
        popup.inflate(R.menu.menu_task);
        popup.setOnMenuItemClickListener(item -> {
            handlePopupAction(item, adapter.getItem(pos));
            return true;
        });
        popup.show();
        return true;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if ((resultCode != RESULT_OK) || (requestCode != REQUEST_TAKE_PHOTO)) { return; }
        new AttachImageTask().execute(selectedTask, imageToBeAttachedPath);
    }

    // -------------------------
    // Camera/Photo
    // -------------------------
    public void dispatchTakePhotoIntent(String taskId) {
        this.selectedTask = taskId;

        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(getContext().getPackageManager()) != null) {
            File photoFile;
            try { photoFile = createImageFile(); }
            catch (IOException e) {
                Log.w(TAG, "Failed creating photo file", e);
                return;
            }

            Uri photoURI = FileProvider.getUriForFile(
                getContext(),
                getContext().getApplicationContext().getPackageName() + ".provider",
                photoFile);
            takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
            startActivityForResult(takePictureIntent, REQUEST_TAKE_PHOTO);
        }
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
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_task));
        final android.view.View view = inflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", (dialog, whichButton) -> {
            String title = input.getText().toString();
            if (title.length() == 0) { return; }
            new CreateTaskTask(parentId).execute(title);
        });
        alert.show();
    }

    private void displayUpdateTaskDialog(Document task) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getContext());
        alert.setTitle(getResources().getString(R.string.title_dialog_update));

        final EditText input = new EditText(getContext());
        input.setMaxLines(1);
        input.setSingleLine(true);
        String text = task.getString("task");
        input.setText(text);
        alert.setView(input);
        alert.setPositiveButton(
            "Ok",
            (dialogInterface, i) ->
                updateTask(task.toMutable(), input.getText().toString()));
        alert.show();
    }

    private File createImageFile() throws IOException {
        String imgFileName = "TODO_LITE-" + dateFormatter.format(new Date());
        File storageDir = getActivity().getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        File image = File.createTempFile(imgFileName, ".jpg", storageDir);
        imageToBeAttachedPath = image.getAbsolutePath();
        return image;
    }

    // -------------------------
    // DAO - CRUD
    // -------------------------

    // update task
    private void updateTask(final MutableDocument task, String text) {
        task.setString("task", text);
        new SaveTask(null).execute(task);
    }

    private ListDetailActivity getDetailActivity() { return (ListDetailActivity) getActivity(); }
}
