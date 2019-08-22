package com.couchbase.todo.pix;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.os.AsyncTask;
import android.util.Log;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.db.DAO;


public class AttachImageTask extends AsyncTask<String, Void, Void> {
    private static final String TAG = "IMG";

    public static final int THUMBNAIL_SIZE = 150;

    /**
     * @param args First arg is the id of the task document; second is the path to the image file
     * @return Void
     */
    @Override
    protected Void doInBackground(String... args) {
        final String taskId = args[0];
        final String imagePath = args[1];

        final File imageFile = new File(imagePath);
        if (!imageFile.exists()) { return null; }

        final Document task = DAO.get().fetch(taskId);
        if (task == null) { return null; }

        final BitmapFactory.Options options = new BitmapFactory.Options();

        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(imagePath, options);

        options.inJustDecodeBounds = false;
        final Bitmap image = BitmapFactory.decodeFile(imagePath, options);

        final Bitmap thumbnail
            = ThumbnailUtils.extractThumbnail(image, THUMBNAIL_SIZE, THUMBNAIL_SIZE);

        if (!imageFile.delete()) { Log.w(TAG, "failed deleting image file"); }

        final ByteArrayOutputStream out = new ByteArrayOutputStream();
        thumbnail.compress(Bitmap.CompressFormat.JPEG, 50, out);

        final ByteArrayInputStream in = new ByteArrayInputStream(out.toByteArray());
        final Blob blob = new Blob("image/jpg", in);

        final MutableDocument mutableTask = task.toMutable();
        mutableTask.setBlob("image", blob);

        DAO.get().save(mutableTask);

        return null;
    }
}
