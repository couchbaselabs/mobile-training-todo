package com.couchbase.todo;

import android.Manifest;
import android.app.AlertDialog;
import android.content.ContentResolver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.AssetFileDescriptor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.support.v4.content.ContextCompat;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.PopupMenu;
import android.widget.TextView;

import com.couchbase.lite.Attachment;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.Document;
import com.couchbase.lite.Emitter;
import com.couchbase.lite.LiveQuery;
import com.couchbase.lite.Mapper;
import com.couchbase.lite.Query;
import com.couchbase.lite.SavedRevision;
import com.couchbase.lite.UnsavedRevision;
import com.couchbase.lite.util.Log;
import com.couchbase.todo.util.LiveQueryAdapter;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static android.app.Activity.RESULT_OK;
import static com.couchbase.todo.ListDetailActivity.INTENT_LIST_ID;


public class TasksFragment extends Fragment {

    private ListView mListView;

    private Database mDatabase;
    private String mUsername;
    public Document mTaskList;

    LiveQuery listsLiveQuery = null;

    private android.view.LayoutInflater mInflater;
    private View mainView;

    private static final int PERMISSION_REQUESTS = 1010;
    private static final int REQUEST_TAKE_PHOTO = 1;
    private static final int REQUEST_CHOOSE_PHOTO = 2;
    private static final int THUMBNAIL_SIZE = 150;

    private String mImagePathToBeAttached;
    private Document selectedTask;

    public TasksFragment() {
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (listsLiveQuery != null) {
            listsLiveQuery.stop();
            listsLiveQuery = null;
        }
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

        mInflater = inflater;
        mainView = inflater.inflate(R.layout.fragment_tasks, null);

        mListView = (ListView) mainView.findViewById(R.id.list);

        FloatingActionButton fab = (FloatingActionButton) mainView.findViewById(R.id.fab);
        fab.setOnClickListener(new android.view.View.OnClickListener() {
            @Override
            public void onClick(android.view.View view) {
                displayCreateDialog();
            }
        });
        fab.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View v) {
                createTaskConflict();
                return true;
            }
        });

        Application application = (Application) getActivity().getApplication();
        mDatabase = application.getDatabase();
        mUsername = application.getUsername();
        Intent intent = getActivity().getIntent();
        mTaskList = mDatabase.getDocument(intent.getStringExtra(INTENT_LIST_ID));

        setupViewAndQuery();

        return mainView;
    }

    private void setupViewAndQuery() {
        com.couchbase.lite.View view = mDatabase.getView("task/tasksByCreatedAt");
        if (view.getMap() == null) {
            view.setMap(new Mapper() {
                @Override
                public void map(Map<String, Object> document, Emitter emitter) {
                    String type = (String) document.get("type");
                    if ("task".equals(type)) {
                        Map<String, Object> taskList = (Map<String, Object>) document.get("taskList");
                        String listId = (String) taskList.get("id");
                        String task = (String) document.get("task");
                        ArrayList<String> key = new ArrayList<String>();
                        key.add(listId);
                        key.add(task);
                        String value = (String) document.get("_rev");
                        emitter.emit(key, value);
                    }
                }
            }, "5.0");
        }

        Query query = view.createQuery();

        ArrayList<String> key = new ArrayList<String>();
        key.add(mTaskList.getId());
        query.setStartKey(key);
        query.setEndKey(key);
        query.setPrefixMatchLevel(1);
        query.setDescending(false);
        listsLiveQuery = query.toLiveQuery();

        final TasksFragment.TaskAdapter mAdapter = new TasksFragment.TaskAdapter(getActivity(), listsLiveQuery);

        mListView.setAdapter(mAdapter);
        mListView.setOnItemLongClickListener(new AdapterView.OnItemLongClickListener() {
            @Override
            public boolean onItemLongClick(AdapterView<?> parent, View view, final int pos, long id) {
                PopupMenu popup = new PopupMenu(getContext(), view);
                popup.inflate(R.menu.list_item);
                popup.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        Document task = (Document) mAdapter.getItem(pos);
                        handleTaskPopupAction(item, task);
                        return true;
                    }
                });
                popup.show();
                return true;
            }
        });

    }

    private void handleTaskPopupAction(MenuItem item, Document task) {
        switch (item.getItemId()) {
            case R.id.update:
                updateTask(task);
                return;
            case R.id.delete:
                deleteTask(task);
                return;
        }
    }

    private void updateTask(final Document task) {
        AlertDialog.Builder alert = new AlertDialog.Builder(getContext());
        alert.setTitle(getResources().getString(R.string.title_dialog_update));

        final EditText input = new EditText(getContext());
        input.setMaxLines(1);
        input.setSingleLine(true);
        String text = (String) task.getProperty("task");
        input.setText(text);
        alert.setView(input);
        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                Map<String, Object> updatedProperties = new HashMap<String, Object>();
                updatedProperties.putAll(task.getProperties());
                updatedProperties.put("task", input.getText().toString());

                try {
                    task.putProperties(updatedProperties);
                } catch (CouchbaseLiteException e) {
                    e.printStackTrace();
                }
            }
        });
        alert.show();
    }

    private void deleteTask(final Document task) {
        try {
            task.delete();
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    }

    private class TaskAdapter extends LiveQueryAdapter {
        public TaskAdapter(Context context, LiveQuery query) {
            super(context, query);
        }

        @Override
        public android.view.View getView(int position, android.view.View convertView, ViewGroup parent) {
            if (convertView == null) {
                LayoutInflater inflater = (LayoutInflater) parent.getContext().
                        getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                convertView = inflater.inflate(R.layout.view_task, null);
            }

            final Document task = (Document) getItem(position);
            if (task == null || task.getCurrentRevision() == null) {
                return convertView;
            }

            ImageView imageView = (ImageView) convertView.findViewById(R.id.photo);
            Bitmap thumbnail = getTaskThumbnail(task);
            if (thumbnail != null)
                imageView.setImageBitmap(thumbnail);
            else
                imageView.setImageDrawable(getResources().getDrawable(R.drawable.ic_camera_light));

            imageView.setOnClickListener(new android.view.View.OnClickListener() {
                @Override
                public void onClick(android.view.View v) {
                    displayAttachImageDialog(task);
                }
            });

            TextView text = (TextView) convertView.findViewById(R.id.text);
            text.setText((String) task.getProperty("task"));

            final CheckBox checkBox = (CheckBox) convertView.findViewById(R.id.checked);
            Boolean checkedProperty = (Boolean) task.getProperty("complete");
            boolean checked = checkedProperty != null ? checkedProperty.booleanValue() : false;
            checkBox.setChecked(checked);
            checkBox.setOnClickListener(new android.view.View.OnClickListener() {
                @Override
                public void onClick(android.view.View view) {
                    updateCheckedStatus(task, checkBox.isChecked());
                }
            });

            return convertView;
        }

        private void updateCheckedStatus(Document task, boolean checked) {
            Map<String, Object> properties = new HashMap<String, Object>();
            properties.putAll(task.getProperties());
            properties.put("complete", checked);

            try {
                task.putProperties(properties);
            } catch (CouchbaseLiteException e) {
                Log.e(Application.TAG, "Cannot update checked status", e);
            }
        }

        private Bitmap getTaskThumbnail(Document task) {
            List<Attachment> attachments = task.getCurrentRevision().getAttachments();
            if (attachments.size() == 0)
                return null;

            Bitmap bitmap = null;
            InputStream is = null;
            final int size = THUMBNAIL_SIZE;
            try {
                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;
                is = attachments.get(0).getContent();
                BitmapFactory.decodeStream(is, null, options);
//                options.inSampleSize = ImageUtil.calculateInSampleSize(options, size, size);
                is.close();

                options.inJustDecodeBounds = false;
                is = task.getCurrentRevision().getAttachments().get(0).getContent();
                bitmap = BitmapFactory.decodeStream(is, null, options);
                bitmap = ThumbnailUtils.extractThumbnail(bitmap, size, size);
            } catch (Exception e) {
                Log.e(Application.TAG, "Cannot decode the attached image", e);
            } finally {
                try { if (is != null) is.close(); } catch (IOException e) { }
            }
            return bitmap;
        }
    }

    private void displayCreateDialog() {
        AlertDialog.Builder alert = new AlertDialog.Builder(getActivity());
        alert.setTitle(getResources().getString(R.string.title_dialog_new_task));

        final android.view.View view = mInflater.inflate(R.layout.view_dialog_input, null);
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
            public void onClick(DialogInterface dialog, int whichButton) { }
        });

        alert.show();
    }

    private SavedRevision createTask(String title) {
        Map<String, Object> taskListInfo = new HashMap<String, Object>();
        taskListInfo.put("id", mTaskList.getId());
        taskListInfo.put("owner", mTaskList.getProperty("owner"));

        Map<String, Object> properties = new HashMap<String, Object>();
        properties.put("type", "task");
        properties.put("taskList", taskListInfo);
        properties.put("createdAt", new Date());
        properties.put("task", title);
        properties.put("complete", false);

        Document document = mDatabase.createDocument();
        try {
            return document.putProperties(properties);
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
            return null;
        }
    }

    private void createTaskConflict() {
        SavedRevision savedRevision = createTask("Text");
        UnsavedRevision newRev1 = savedRevision.createRevision();
        Map<String, Object> propsRev1 = newRev1.getProperties();
        propsRev1.put("task", "Text Changed");
        UnsavedRevision newRev2 = savedRevision.createRevision();
        Map<String, Object> propsRev2 = newRev2.getProperties();
        propsRev2.put("complete", true);
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

    private void attachImage(Document task, Bitmap image) {
        UnsavedRevision revision = task.createRevision();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        image.compress(Bitmap.CompressFormat.JPEG, 50, out);
        ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());
        revision.setAttachment("image", "image/jpg", in);

        try {
            revision.save();
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    }

    private void dispatchTakePhotoIntent() {
        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(this.getActivity().getPackageManager()) != null) {
            File photoFile = null;
            try {
                photoFile = createImageFile();
            } catch (IOException e) {
                e.printStackTrace();
            }

            if (photoFile != null) {
                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(photoFile));
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

    private void dispatchChoosePhotoIntent() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Audio.Media.EXTERNAL_CONTENT_URI);
        intent.setType("image/*");
        startActivityForResult(Intent.createChooser(intent, "Select File"), REQUEST_CHOOSE_PHOTO);
    }

    private void deleteCurrentPhoto(Document task) {
        UnsavedRevision unsavedRevision = task.getCurrentRevision().createRevision();
        unsavedRevision.removeAttachment("image");
        try {
            unsavedRevision.save();
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        switch (requestCode) {
            case PERMISSION_REQUESTS: {
                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    showImagePickerDialog();
                }
            }
        }
    }

    private void displayAttachImageDialog(final Document task) {
        selectedTask = task;
        if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.CAMERA}, PERMISSION_REQUESTS);
        } else {
            showImagePickerDialog();
        }
    }

    private void showImagePickerDialog() {
        CharSequence[] items;
        items = new CharSequence[]{ "Take photo", "Choose photo", "Delete photo" };

        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        builder.setTitle("Add picture");
        builder.setItems(items, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int item) {
                if (item == 0) {
                    dispatchTakePhotoIntent();
                } else if (item == 1) {
                    dispatchChoosePhotoIntent();
                } else {
                    deleteCurrentPhoto(selectedTask);
                }
            }
        });
        builder.show();
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (resultCode != RESULT_OK) {
            return;
        }

        final int size = THUMBNAIL_SIZE;
        Bitmap thumbnail = null;
        if (requestCode == REQUEST_TAKE_PHOTO) {
            File file = new File(mImagePathToBeAttached);
            if (file.exists()) {
                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;
                BitmapFactory.decodeFile(mImagePathToBeAttached, options);
                options.inJustDecodeBounds = false;
                Bitmap mImage = BitmapFactory.decodeFile(mImagePathToBeAttached, options);
                thumbnail = ThumbnailUtils.extractThumbnail(mImage, size, size);
                file.delete();
            }
        } else if (requestCode == REQUEST_CHOOSE_PHOTO) {
            Uri uri = data.getData();
            ContentResolver resolver = getActivity().getContentResolver();
            Bitmap mImage = null;
            try {
                mImage = MediaStore.Images.Media.getBitmap(resolver, uri);
            } catch (IOException e) {
                e.printStackTrace();
            }
            AssetFileDescriptor asset = null;
            try {
                asset = resolver.openAssetFileDescriptor(uri, "r");
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            }
            thumbnail = ThumbnailUtils.extractThumbnail(mImage, size, size);
        }

        attachImage(selectedTask, thumbnail);
    }
}
