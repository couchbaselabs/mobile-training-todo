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
import android.text.Editable;
import android.text.TextUtils;
import android.util.Log;
import android.widget.CheckBox;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.textfield.TextInputEditText;

import com.couchbase.todo.config.Config;
import com.couchbase.todo.db.DAO;


public class ConfigActivity extends AppCompatActivity {
    private static final String TAG = "CONFIG";

    private static class LogoutTask extends AsyncTask<Void, Void, Void> {
        @SuppressLint("StaticFieldLeak")
        private ConfigActivity act; // referenced only from the Main thread.

        public LogoutTask(ConfigActivity act) { this.act = act; }

        @Override
        protected Void doInBackground(Void... unused) {
            DAO.get().logout();
            return null;
        }

        @Override
        protected void onPostExecute(Void ignore) { act.finish(); }
    }

    public static void start(Activity act) {
        Intent intent = new Intent(act, ConfigActivity.class);
        act.startActivity(intent);
    }

    private CheckBox loggingCheckBox;
    private CheckBox loginCheckBox;
    private CheckBox ccrEnabledCheckBox;
    private TextInputEditText dbNameView;
    private TextInputEditText sgUrlView;

    // Herisy!!  Ignore the back button.
    @Override
    public void onBackPressed() { }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        Log.d(TAG, "create config");
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_config);

        loggingCheckBox = findViewById(R.id.loggingEnabled);
        loginCheckBox = findViewById(R.id.loginEnabled);
        ccrEnabledCheckBox = findViewById(R.id.ccrEnabled);

        dbNameView = findViewById(R.id.dbName);
        sgUrlView = findViewById(R.id.sgUrl);

        findViewById(R.id.btnUpdate).setOnClickListener(view -> update());
        findViewById(R.id.btnCancel).setOnClickListener(view -> finish());

        populateView();
    }

    private void populateView() {
        Config config = Config.get();

        loggingCheckBox.setChecked(config.isLoggingEnabled());
        loginCheckBox.setChecked(config.isLoginEnabled());
        ccrEnabledCheckBox.setChecked(config.isCcrEnabled());

        dbNameView.setText(config.getDbName());
        sgUrlView.setText(config.getSgUrl());
    }

    private void update() {
        final Editable dbName = dbNameView.getText();
        if (TextUtils.isEmpty(dbName)) {
            Toast.makeText(this, "Default database name may not be empty", Toast.LENGTH_SHORT).show();
            return;
        }

        final Editable sgUrl = sgUrlView.getText();

        boolean updated = Config.get().update(
            loggingCheckBox.isChecked(),
            loginCheckBox.isChecked(),
            ccrEnabledCheckBox.isChecked(),
            dbName.toString(),
            (TextUtils.isEmpty(sgUrl)) ? null : sgUrl.toString());

        if (updated) { new LogoutTask(this).execute(); }
    }
}