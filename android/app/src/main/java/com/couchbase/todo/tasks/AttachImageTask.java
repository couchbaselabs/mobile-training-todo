package com.couchbase.todo.tasks;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;


public class AttachImageTask extends Scheduler.BackgroundTask<String, Void> {
    private static final String TAG = "TASK_IMG";

    public static final int THUMBNAIL_SIZE = 150;
    private final String imagePath;

    public AttachImageTask(@NonNull String imagePath) { this.imagePath = imagePath; }

    /**
     * @param taskId First arg is the id of the task document
     * @return Void
     */
    @Override
    protected Void doInBackground(String taskId) {
        final File imageFile = new File(imagePath);
        if (!imageFile.exists()) { return null; }

        final Document task = DatabaseService.get().fetchDoc(DatabaseService.COLLECTION_TASKS, taskId);
        if (task == null) { return null; }

        final BitmapFactory.Options options = new BitmapFactory.Options();

        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(imagePath, options);

        options.inJustDecodeBounds = false;
        final Bitmap image = BitmapFactory.decodeFile(imagePath, options);

        final Bitmap thumbnail = ThumbnailUtils.extractThumbnail(image, THUMBNAIL_SIZE, THUMBNAIL_SIZE);

        if (!imageFile.delete()) { Log.w(TAG, "failed deleting image file"); }

        final ByteArrayOutputStream out = new ByteArrayOutputStream();
        thumbnail.compress(Bitmap.CompressFormat.JPEG, 50, out);

        final ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());
        final Blob blob = new Blob("image/jpg", in);

        final MutableDocument mutableTask = task.toMutable();
        mutableTask.setBlob("image", blob);

        DatabaseService.get().saveDoc(DatabaseService.COLLECTION_TASKS, mutableTask);

        return null;
    }
}
