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

import com.couchbase.lite.AbstractReplicator;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.todo.db.DAO;


public abstract class ToDoActivity extends AppCompatActivity {
    private static final String TAG = "ACT_BASE";

    private static Map<AbstractReplicator.ActivityLevel, Integer> colorMap;

    private static void buildColorMap(Context ctxt) {
        if (colorMap != null) { return; }

        final Map<AbstractReplicator.ActivityLevel, Integer> cMap = new HashMap<>();
        cMap.put(AbstractReplicator.ActivityLevel.CONNECTING, ctxt.getColor(R.color.connecting));
        cMap.put(AbstractReplicator.ActivityLevel.IDLE, ctxt.getColor(R.color.idle));
        cMap.put(AbstractReplicator.ActivityLevel.BUSY, ctxt.getColor(R.color.busy));
        cMap.put(AbstractReplicator.ActivityLevel.STOPPED, ctxt.getColor(R.color.failed));
        cMap.put(AbstractReplicator.ActivityLevel.OFFLINE, ctxt.getColor(R.color.failed));
        colorMap = cMap;
    }

    private DAO dao;
    private Window rootWindow;

    @Override
    public final boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public final boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.logout) {
            DAO.get().logout();
            LoginActivity.start(this);
            finish();
            return true;
        }

        if (item.getItemId() == R.id.config) {
            ConfigActivity.start(this);
            return true;
        }

        if (item.getItemId() == R.id.delete) {
            DAO.get().logout(true);
            LoginActivity.start(this);
            finish();
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    protected abstract void onCreateLoggedIn(@Nullable Bundle state);

    @Override
    protected final void onCreate(@Nullable Bundle state) {
        super.onCreate(state);

        buildColorMap(this);

        if (!verifyLoggedIn()) { return; }

        onCreateLoggedIn(state);

        rootWindow = getWindow();
    }

    @Override
    protected final void onPause() {
        super.onPause();

        DAO.get().registerListener(null);
    }

    @Override
    protected final void onResume() {
        super.onResume();

        verifyLoggedIn();

        DAO.get().registerListener(
            new DAO.DAOListener() {
                @Override
                public void onError(CouchbaseLiteException e) { onDbError(e); }

                @Override
                public void onNewState(AbstractReplicator.ActivityLevel s) { updateState(s); }
            }
        );
    }

    final void onDbError(CouchbaseLiteException err) {
        Toast.makeText(this, "DB error: " + err.getMessage(), Toast.LENGTH_LONG).show();
    }

    private void updateState(AbstractReplicator.ActivityLevel state) {
        final Integer color = colorMap.get(state);
        rootWindow.setStatusBarColor((color != null)
            ? color
            : colorMap.get(AbstractReplicator.ActivityLevel.OFFLINE));
    }

    private boolean verifyLoggedIn() {
        final DAO oldDao = dao;
        dao = DAO.get();
        if (dao.isLoggedIn(oldDao)) { return true; }

        LoginActivity.start(this);

        finish();

        return false;
    }
}
