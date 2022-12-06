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

import android.content.Context;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.Window;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import java.util.HashMap;
import java.util.Map;

import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.todo.app.ToDo;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.tasks.DbDumper;


public abstract class ToDoActivity extends AppCompatActivity {
    private static final String TAG = "ACT_BASE";

    @Nullable
    private static Map<ReplicatorActivityLevel, Integer> colorMap;

    @NonNull
    private static Map<ReplicatorActivityLevel, Integer> buildColorMap(@NonNull Context ctxt) {
        final Map<ReplicatorActivityLevel, Integer> cMap = new HashMap<>();
        cMap.put(ReplicatorActivityLevel.CONNECTING, ctxt.getColor(R.color.connecting));
        cMap.put(ReplicatorActivityLevel.IDLE, ctxt.getColor(R.color.idle));
        cMap.put(ReplicatorActivityLevel.BUSY, ctxt.getColor(R.color.busy));
        cMap.put(ReplicatorActivityLevel.STOPPED, ctxt.getColor(R.color.failed));
        cMap.put(ReplicatorActivityLevel.OFFLINE, ctxt.getColor(R.color.failed));
        return cMap;
    }

    @Nullable
    private DatabaseService dao;
    @Nullable private Window rootWindow;

    @Override
    public final boolean onCreateOptionsMenu(@NonNull Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public final boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.logout) {
            DatabaseService.get().logout();
            LoginActivity.start(this);
            finish();
            return true;
        }

        if (item.getItemId() == R.id.config) {
            ConfigActivity.start(this);
            return true;
        }

        if (item.getItemId() == R.id.delete) {
            DatabaseService.get().logout(true);
            LoginActivity.start(this);
            finish();
            return true;
        }

        if (item.getItemId() == R.id.startServer) {
            ListenerActivity.start(this);
            return true;
        }

        if (item.getItemId() == R.id.dumpAll) {
            new DbDumper().execute();
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    protected abstract void onCreateLoggedIn(@Nullable Bundle state);

    @Override
    protected final void onCreate(@Nullable Bundle state) {
        super.onCreate(state);

        if (!verifyLoggedIn()) { return; }

        if (colorMap == null) { colorMap = buildColorMap(this); }

        onCreateLoggedIn(state);

        rootWindow = getWindow();
    }

    @Override
    protected final void onPause() {
        super.onPause();

        ToDo.get().registerListener(null);
    }

    @Override
    protected final void onResume() {
        super.onResume();

        verifyLoggedIn();

        ToDo.get().registerListener(
            new ToDo.Listener() {
                @Override
                public void onError(Exception e) { onAppError(e); }

                @Override
                public void onNewReplicatorState(ReplicatorActivityLevel s) { updateState(s); }
            }
        );
    }

    protected int getColorForReplicatorState(@NonNull ReplicatorActivityLevel state) {
        final Integer color = colorMap.get(state);
        return (color != null)
            ? color
            : colorMap.get(ReplicatorActivityLevel.OFFLINE);
    }

    final void onAppError(@NonNull Exception err) {
        Toast.makeText(this, "System error: " + err.getMessage(), Toast.LENGTH_LONG).show();
    }

    private void updateState(@NonNull ReplicatorActivityLevel state) {
        rootWindow.setStatusBarColor(getColorForReplicatorState(state));
    }

    private boolean verifyLoggedIn() {
        final DatabaseService oldDao = dao;
        dao = DatabaseService.get();
        if (dao.isLoggedIn(oldDao)) { return true; }

        LoginActivity.start(this);

        finish();

        return false;
    }
}
