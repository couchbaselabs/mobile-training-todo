package com.couchbase.todo;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.support.v4.content.FileProvider;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.PopupMenu;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import static android.app.Activity.RESULT_OK;
import static android.os.Build.VERSION_CODES.M;

public class TasksFragment extends Fragment {

    private static final int REQUEST_TAKE_PHOTO = 1;
    private static final int REQUEST_CHOOSE_PHOTO = 2;
    private static final int THUMBNAIL_SIZE = 150;

    private ListView listView;
    private LiveTasksAdapter adapter;

    private Database db;
    private Document taskList;

    private String mImagePathToBeAttached;
    private Document selectedTask;

    public TasksFragment() {
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

        adapter = new LiveTasksAdapter(this, db, taskList.getId());
        listView = view.findViewById(R.id.list);
        listView.setAdapter(adapter);
        listView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener() {
            @Override
            public boolean onItemLongClick(AdapterView<?> parent, View view, final int pos, long id) {
                PopupMenu popup = new PopupMenu(getContext(), view);
                popup.inflate(R.menu.list_item);
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

        return view;
    }

    private void handlePopupAction(MenuItem item, Document task) {
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
    private void displayCreateDialog(LayoutInflater inflater) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_task));
        final android.view.View view = inflater.inflate(R.layout.view_dialog_input, null);
        final EditText input = view.findViewById(R.id.text);
        alert.setView(view);
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int whichButton) {
                String title = input.getText().toString();
                if (title.length() == 0)
                    return;
                createTask(title);
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
    // Camera/Photo
    // -------------------------
    protected void dispatchTakePhotoIntent(final Document task) {
        this.selectedTask = task;

        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(getContext().getPackageManager()) != null) {
            File photoFile = null;
            try {
                photoFile = createImageFile();
            } catch (IOException e) {
                e.printStackTrace();
            }

            if (photoFile != null) {
                // NOTE: API 24 or higher.....
                if (Build.VERSION.SDK_INT > M) {
                    Uri photoURI = FileProvider.getUriForFile(getContext(), getContext().getApplicationContext().getPackageName() + ".provider", photoFile);
                    takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
                } else {
                    takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(photoFile));
                }
                startActivityForResult(takePictureIntent, REQUEST_TAKE_PHOTO);
            }
        }
    }

    private File createImageFile() throws IOException {
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        String fileName = "TODO_LITE-" + timeStamp + "_";
        File storageDir = getActivity().getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        File image = File.createTempFile(fileName, ".jpg", storageDir);
        mImagePathToBeAttached = image.getAbsolutePath();
        return image;
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
                attachImage(selectedTask, thumbnail);
            }
        }
    }

    // -------------------------
    // Database - CRUD
    // -------------------------

    // create task
    private void createTask(String title) {
        Document doc = new Document();
        doc.set("type", "task");
        Map<String, Object> taskListInfo = new HashMap<String, Object>();
        taskListInfo.put("id", taskList.getId());
        taskListInfo.put("owner", taskList.getString("owner"));
        doc.set("taskList", taskListInfo);
        doc.set("createdAt", new Date());
        doc.set("task", title);
        doc.set("complete", false);
        db.save(doc);
    }

    // update task
    private void updateTask(final Document task, String text) {
        task.set("task", text);
        db.save(task);
    }

    // delete task
    private void deleteTask(final Document task) {
        db.delete(task);
    }

    // store photo
    private void attachImage(Document task, Bitmap image) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        image.compress(Bitmap.CompressFormat.JPEG, 50, out);
        ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());

        Blob blob = new Blob("image/jpg", in);
        task.set("image", blob);
        db.save(task);
    }
}
