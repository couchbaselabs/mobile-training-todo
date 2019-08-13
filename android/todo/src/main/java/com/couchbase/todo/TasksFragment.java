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
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.db.DAO;
import com.couchbase.todo.ui.TasksAdapter;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;
import androidx.fragment.app.Fragment;

import static android.app.Activity.RESULT_OK;
import static android.os.Build.VERSION_CODES.M;


public class TasksFragment extends Fragment {
    private static final String TAG = TasksFragment.class.getSimpleName();

    private static final int REQUEST_TAKE_PHOTO = 1;
    private static final int REQUEST_CHOOSE_PHOTO = 2;
    private static final int THUMBNAIL_SIZE = 150;

    private ListView listView;
    private TasksAdapter adapter;

    private Document taskList;

    private String mImagePathToBeAttached;
    private Document selectedTask;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_tasks, container, false);

        FloatingActionButton fab = view.findViewById(R.id.fab);
        fab.setOnClickListener(view12 -> displayCreateDialog(inflater));

        taskList = DAO.get().fetchDocument(getActivity().getIntent().getStringExtra(ListsActivity.INTENT_LIST_ID));

        adapter = new TasksAdapter(this, taskList.getId());
        listView = view.findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemLongClickListener((parent, view1, pos, id) -> { showPopup(view1, pos); return true; });

        return view;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == RESULT_OK && requestCode == REQUEST_TAKE_PHOTO) {
            File file = new File(mImagePathToBeAttached);
            if (file.exists()) {
                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;
                BitmapFactory.decodeFile(mImagePathToBeAttached, options);
                options.inJustDecodeBounds = false;
                Bitmap mImage = BitmapFactory.decodeFile(mImagePathToBeAttached, options);
                Bitmap thumbnail = ThumbnailUtils.extractThumbnail(mImage, THUMBNAIL_SIZE, THUMBNAIL_SIZE);
                file.delete();
                selectedTask = attachImage(selectedTask.toMutable(), thumbnail);
            }
        }
    }

    // -------------------------
    // Camera/Photo
    // -------------------------
    public void dispatchTakePhotoIntent(final Document task) {
        this.selectedTask = task;

        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(getContext().getPackageManager()) != null) {
            File photoFile = null;
            try {
                photoFile = createImageFile();
            }
            catch (IOException e) {
                e.printStackTrace();
            }

            if (photoFile != null) {
                // NOTE: API 24 or higher.....
                if (Build.VERSION.SDK_INT > M) {
                    Uri photoURI = FileProvider.getUriForFile(
                        getContext(),
                        getContext().getApplicationContext().getPackageName() + ".provider",
                        photoFile);
                    takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
                }
                else {
                    takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(photoFile));
                }
                startActivityForResult(takePictureIntent, REQUEST_TAKE_PHOTO);
            }
        }
    }

    private void showPopup(View view1, int pos) {
        PopupMenu popup = new PopupMenu(getContext(), view1);
        popup.inflate(R.menu.menu_list);
        popup.setOnMenuItemClickListener(item -> {
            handlePopupAction(item, DAO.get().fetchDocument(adapter.getItem(pos)));
            return true;
        });
        popup.show();
    }

    private void handlePopupAction(MenuItem item, Document task) {
        switch (item.getItemId()) {
            case R.id.action_update:
                displayUpdateTaskDialog(task);
                break;
            case R.id.action_delete:
                deleteTask(task);
                break;
        }
    }

    // display create task dialog
    private void displayCreateDialog(LayoutInflater inflater) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_task));
        final android.view.View view = inflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", (dialog, whichButton) -> {
            String title = input.getText().toString();
            if (title.length() == 0) { return; }
            createTask(title);
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
        alert.setPositiveButton("Ok", (dialogInterface, i) -> updateTask(task.toMutable(), input.getText().toString()));
        alert.show();
    }

    private File createImageFile() throws IOException {
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
        String fileName = "TODO_LITE-" + timeStamp + "_";
        File storageDir = getActivity().getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        File image = File.createTempFile(fileName, ".jpg", storageDir);
        mImagePathToBeAttached = image.getAbsolutePath();
        return image;
    }

    // -------------------------
    // DAO - CRUD
    // -------------------------

    // create task
    private void createTask(String title) {
        MutableDocument mDoc = new MutableDocument();
        mDoc.setString("type", "task");
        Map<String, Object> taskListInfo = new HashMap<>();
        taskListInfo.put("id", taskList.getId());
        taskListInfo.put("owner", taskList.getString("owner"));
        mDoc.setValue("taskList", taskListInfo);
        mDoc.setDate("createdAt", new Date());
        mDoc.setString("task", title);
        mDoc.setBoolean("complete", false);
        DAO.get().save(mDoc);
    }

    // update task
    private void updateTask(final MutableDocument task, String text) {
        task.setString("task", text);
        DAO.get().save(task);
    }

    // delete task
    private void deleteTask(final Document task) {
        DAO.get().delete(task);
    }

    // store photo
    private Document attachImage(MutableDocument task, Bitmap image) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        image.compress(Bitmap.CompressFormat.JPEG, 50, out);
        ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());

        Blob blob = new Blob("image/jpg", in);
        task.setBlob("image", blob);
        return DAO.get().save(task);
    }
}
