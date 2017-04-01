package com.couchbase.todo;

import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseOptions;

public class Application extends android.app.Application {
    private final String DATABASE_NAME = "todo";

    private Database db = null;
    private String username = DATABASE_NAME;

    @Override
    public void onCreate() {
        super.onCreate();
        openDatabase(username);
    }

    @Override
    public void onTerminate() {
        closeDatabase();
        super.onTerminate();
    }

    public Database getDatabase() {
        return db;
    }

    public String getUsername() {
        return username;
    }

    // -------------------------
    // Database operation
    // -------------------------

    private void openDatabase(String dbname) {
        DatabaseOptions options = new DatabaseOptions();
        options.setDirectory(getFilesDir());
        db = new Database(dbname, options);
    }

    private void closeDatabase() {
        if (db != null)
            db.close();
    }
}
