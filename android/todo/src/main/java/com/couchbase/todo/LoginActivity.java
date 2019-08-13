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
import android.util.Log;
import android.widget.EditText;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.couchbase.todo.db.DAO;


public class LoginActivity extends AppCompatActivity {
    private static final String TAG = "LOGIN";

    private static class LoginTask extends AsyncTask<String, Void, String> {
        @SuppressLint("StaticFieldLeak")
        private LoginActivity ctxt;

        public LoginTask(LoginActivity ctxt) { this.ctxt = ctxt; }

        // args are username, password
        @Override
        protected String doInBackground(String... creds) {
            return DAO.get().login(ctxt, creds[0], creds[1]);
        }

        @Override
        protected void onCancelled() { ctxt = null; }

        @Override
        protected void onPostExecute(String msg) {
            if (ctxt != null) { ctxt.onLogin(msg); }
        }
    }

    public static void start(Activity act) {
        Intent intent = new Intent(act, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK); // always a new task
        act.startActivity(intent);
        act.finish();
    }


    private EditText nameView;
    private EditText pwdView;
    private LoginTask loginTask;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        Log.d(TAG, "create login");
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_login);

        nameView = findViewById(R.id.nameInput);
        pwdView = findViewById(R.id.passwordInput);

        findViewById(R.id.btnLogin).setOnClickListener(view -> login());
    }

    @Override
    protected void onPause() {
        Log.d(TAG, "pause login");
        super.onPause();

        if (loginTask != null) {
            loginTask.cancel(true);
            loginTask = null;
        }
    }

    @Override
    protected void onResume() {
        Log.d(TAG, "resume login");
        super.onResume();
        if (DAO.get().isLoggedIn()) { nextPage(); }
    }

    void login() {
        loginTask = new LoginTask(this);
        loginTask.execute(nameView.getText().toString(), pwdView.getText().toString());
    }

    void onLogin(String msg) {
        loginTask = null;

        if (msg != null) {
            Toast.makeText(this, "Login failed: " + msg, Toast.LENGTH_LONG).show();
            return;
        }

        nextPage();
    }

    private void nextPage() {
        ListsActivity.start(this, Intent.FLAG_ACTIVITY_NEW_TASK);
        finish();
    }
}
