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
import android.app.Activity;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.text.TextUtils;
import android.widget.EditText;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import java.util.Arrays;

import com.couchbase.todo.config.Config;
import com.couchbase.todo.db.DAO;


public class LoginActivity extends AppCompatActivity {
    private static final String TAG = "ACT_LOGIN";

    private static class LoginTask extends AsyncTask<Void, Void, Void> {
        @NonNull
        private final String username;
        @NonNull
        private final char[] password;
        @Nullable
        @SuppressLint("StaticFieldLeak")
        private LoginActivity ctxt;

        LoginTask(@NonNull LoginActivity ctxt, @NonNull String username, @NonNull char[] password) {
            this.ctxt = ctxt;
            this.username = username;
            this.password = password;
        }

        // args are username, password
        @Override
        protected Void doInBackground(Void... ignore) {
            DAO.get().login(username, password);
            return null;
        }

        @Override
        protected void onCancelled() { ctxt = null; }

        @Override
        protected void onPostExecute(Void ignore) {
            Arrays.fill(password, ' ');
            if (ctxt != null) { ctxt.onLogin(); }
        }
    }

    public static void start(@NonNull Activity act) {
        final Intent intent = new Intent(act, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
        act.startActivity(intent);
        act.finish();
    }


    private EditText nameView;
    private EditText pwdView;
    private LoginTask loginTask;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (DAO.get().isLoggedIn(null)) { nextPage(); }

        setContentView(R.layout.activity_login);

        pwdView = findViewById(R.id.passwordInput);

        nameView = findViewById(R.id.nameInput);

        findViewById(R.id.btnLogin).setOnClickListener(view -> login());
    }

    @Override
    protected void onPause() {
        super.onPause();

        if (loginTask != null) {
            loginTask.cancel(true);
            loginTask = null;
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (DAO.get().isLoggedIn(null)) { nextPage(); }
    }

    void login() {
        String username = nameView.getText().toString();
        if (TextUtils.isEmpty(username)) { username = Config.get().getDbName(); }
        if (TextUtils.isEmpty(username)) {
            Toast.makeText(this, R.string.err_no_username, Toast.LENGTH_SHORT).show();
            return;
        }

        final char[] password = new char[pwdView.length()];
        pwdView.getText().getChars(0, password.length, password, 0);

        loginTask = new LoginTask(this, username, password);
        loginTask.execute();
    }

    void onLogin() {
        loginTask = null;
        nextPage();
    }

    private void nextPage() {
        ListsActivity.start(this);
        finish();
    }
}
