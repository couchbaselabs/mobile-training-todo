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

import android.annotation.SuppressLint;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.couchbase.todo.db.DAO;


public abstract class ToDoActivity extends AppCompatActivity {
    private static final String TAG = "ACT";

    private static class LogoutTask extends AsyncTask<Void, Void, Void> {
        @SuppressLint("StaticFieldLeak")
        private ToDoActivity act; // referenced only from the Main thread.

        public LogoutTask(ToDoActivity act) { this.act = act; }

        @Override
        protected Void doInBackground(Void... unused) {
            DAO.get().logout();
            return null;
        }

        @Override
        protected void onCancelled() { act = null; }

        @Override
        protected void onPostExecute(Void ignore) {
            if (act != null) { act.loggedOut(); }
        }
    }


    private LogoutTask logoutTask;

    @Override
    public final boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public final boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.logout) {
            logoutTask = new LogoutTask(this);
            logoutTask.execute();
            return true;
        }

        if (item.getItemId() == R.id.config) {
            ConfigActivity.start(this);
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    protected abstract void onCreateLoggedIn(@Nullable Bundle state);

    @Override
    protected final void onCreate(@Nullable Bundle state) {
        Log.d(TAG, "create " + getClass().getSimpleName());
        super.onCreate(state);

        if (!verifyLoggedIn()) { return; }

        onCreateLoggedIn(state);
    }

    @Override
    protected final void onPause() {
        Log.d(TAG, "pause " + getClass().getSimpleName());
        super.onPause();

        if (logoutTask != null) {
            logoutTask.cancel(true);
            logoutTask = null;
        }
    }

    @Override
    protected final void onResume() {
        Log.d(TAG, "resume " + getClass().getSimpleName());
        super.onResume();

        verifyLoggedIn();
    }

    final void loggedOut() {
        logoutTask = null;
        verifyLoggedIn();
    }

    private boolean verifyLoggedIn() {
        if (DAO.get().isLoggedIn()) { return true; }

        LoginActivity.start(this);

        finish();

        return false;
    }
}
