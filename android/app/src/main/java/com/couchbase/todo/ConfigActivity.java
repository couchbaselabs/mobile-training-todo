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
import com.couchbase.todo.service.ConfigurationService;
import com.couchbase.todo.service.DatabaseService;


public class ConfigActivity extends AppCompatActivity {
    private static final String TAG = "ACT_CONFIG";

    public static void start(@NonNull Activity act) { act.startActivity(new Intent(act, ConfigActivity.class)); }


    @Nullable
    private CheckBox loggingCheckBox;
    @Nullable private CheckBox loginCheckBox;
    @Nullable private TextInputEditText dbNameView;
    @Nullable private TextInputEditText sgUriView;
    @Nullable private CheckBox ccrLocalCheckBox;
    @Nullable private CheckBox ccrRemoteCheckBox;

    @Nullable private TextInputEditText retriesView;
    @Nullable private TextInputEditText timeoutView;

    // Heresy!!  Ignore the back button.
    @Override
    public void onBackPressed() { }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_config);

        final TextView version = findViewById(R.id.version);
        version.setText(CBLVersion.getVersionInfo());

        loggingCheckBox = findViewById(R.id.loggingEnabled);
        loginCheckBox = findViewById(R.id.loginRequired);

        dbNameView = findViewById(R.id.dbName);
        sgUriView = findViewById(R.id.sgUri);

        ccrLocalCheckBox = findViewById(R.id.ccrLocalWins);
        ccrRemoteCheckBox = findViewById(R.id.ccrRemoteWins);
        ccrLocalCheckBox.setOnClickListener(v -> ccrRemoteCheckBox.setChecked(false));
        ccrRemoteCheckBox.setOnClickListener(v -> ccrLocalCheckBox.setChecked(false));

        retriesView = findViewById(R.id.retries);
        timeoutView = findViewById(R.id.timeout);

        findViewById(R.id.btnUpdate).setOnClickListener(view -> update());
        findViewById(R.id.btnCancel).setOnClickListener(view -> finish());

        populateView();
    }

    private void populateView() {
        final ConfigurationService config = ConfigurationService.get();

        loggingCheckBox.setChecked(config.isLoggingEnabled());
        loginCheckBox.setChecked(config.isLoginRequired());

        setCcrState(config.getCcrState());

        dbNameView.setText(config.getDbName());
        sgUriView.setText(config.getSgUri());

        retriesView.setText(String.valueOf(config.getRetries()));
        timeoutView.setText(String.valueOf(config.getWaitTime()));
    }

    private void update() {
        final Editable eDbName = dbNameView.getText();
        final String dbName = (TextUtils.isEmpty(eDbName)) ? null : eDbName.toString();

        final Editable eSgUri = sgUriView.getText();
        final String sgUri = (TextUtils.isEmpty(eSgUri)) ? null : eSgUri.toString();

        final Editable eRetries = retriesView.getText();
        final int retries = (TextUtils.isEmpty(eRetries)) ? 0 : Integer.parseInt(eRetries.toString());

        final Editable eTimeout = timeoutView.getText();
        final int timeout = (TextUtils.isEmpty(eTimeout)) ? 0 : Integer.parseInt(eTimeout.toString());

        final boolean updated = ConfigurationService.get().update(
            loggingCheckBox.isChecked(),
            loginCheckBox.isChecked(),
            ccrLocalCheckBox.isChecked(),
            ccrRemoteCheckBox.isChecked(),
            dbName,
            sgUri,
            retries,
            timeout);

        if (updated) { DatabaseService.get().logout(); }

        finish();
    }

    private void setCcrState(ConfigurationService.CcrState state) {
        ccrLocalCheckBox.setChecked(state == ConfigurationService.CcrState.LOCAL);
        ccrRemoteCheckBox.setChecked(state == ConfigurationService.CcrState.REMOTE);
    }
}
