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

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextUtils;
import android.widget.CheckBox;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.textfield.TextInputEditText;

import com.couchbase.lite.internal.core.CBLVersion;
import com.couchbase.todo.config.Config;
import com.couchbase.todo.db.DAO;


public class ConfigActivity extends AppCompatActivity {
    private static final String TAG = "ACT_CONFIG";

    public static void start(@NonNull Activity act) { act.startActivity(new Intent(act, ConfigActivity.class)); }


    private CheckBox loggingCheckBox;
    private CheckBox loginCheckBox;
    private TextInputEditText dbNameView;
    private TextInputEditText sgUriView;
    private CheckBox ccrLocalCheckBox;
    private CheckBox ccrRemoteCheckBox;

    // Heresy!!  Ignore the back button.
    @Override
    public void onBackPressed() { }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_config);

        TextView version = findViewById(R.id.version);
        version.setText(CBLVersion.getVersionInfo());

        loggingCheckBox = findViewById(R.id.loggingEnabled);
        loginCheckBox = findViewById(R.id.loginRequired);

        dbNameView = findViewById(R.id.dbName);
        sgUriView = findViewById(R.id.sgUri);

        ccrLocalCheckBox = findViewById(R.id.ccrLocalWins);
        ccrRemoteCheckBox = findViewById(R.id.ccrRemoteWins);
        ccrLocalCheckBox.setOnClickListener(v -> ccrRemoteCheckBox.setChecked(false));
        ccrRemoteCheckBox.setOnClickListener(v -> ccrLocalCheckBox.setChecked(false));

        findViewById(R.id.btnUpdate).setOnClickListener(view -> update());
        findViewById(R.id.btnCancel).setOnClickListener(view -> finish());

        populateView();
    }

    private void populateView() {
        final Config config = Config.get();

        loggingCheckBox.setChecked(config.isLoggingEnabled());
        loginCheckBox.setChecked(config.isLoginRequired());

        setCcrState(config.getCcrState());

        dbNameView.setText(config.getDbName());
        sgUriView.setText(config.getSgUri());
    }

    private void update() {
        final Editable eDbName = dbNameView.getText();
        final String dbName = (TextUtils.isEmpty(eDbName)) ? null : eDbName.toString();

        final Editable eSgUri = sgUriView.getText();
        final String sgUri = (TextUtils.isEmpty(eSgUri)) ? null : eSgUri.toString();

        final boolean updated = Config.get().update(
            loggingCheckBox.isChecked(),
            loginCheckBox.isChecked(),
            getCcrState(),
            dbName,
            sgUri);

        if (updated) { DAO.get().logout(); }

        finish();
    }

    private Config.CcrState getCcrState() {
        return (ccrRemoteCheckBox.isChecked())
            ? Config.CcrState.REMOTE
            : ((ccrLocalCheckBox.isChecked())
                ? Config.CcrState.LOCAL
                : Config.CcrState.OFF);
    }

    private void setCcrState(Config.CcrState state) {
        ccrLocalCheckBox.setChecked(state == Config.CcrState.LOCAL);
        ccrRemoteCheckBox.setChecked(state == Config.CcrState.REMOTE);
    }
}
