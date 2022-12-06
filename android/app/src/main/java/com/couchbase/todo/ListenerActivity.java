package com.couchbase.todo;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.concurrent.atomic.AtomicReference;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorChange;
import com.couchbase.todo.service.ListenerService;


public class ListenerActivity extends ToDoActivity {
    private static final String TAG = "LISTEN_ACT";

    public static void start(@NonNull Activity act) { act.startActivity(new Intent(act, ListenerActivity.class)); }

    @Nullable
    private View bgView;
    @Nullable
    private FloatingActionButton startBtn;

    @Nullable
    private final AtomicReference<ListenerService.DBCopier> copier = new AtomicReference<>();

    @Override
    protected void onCreateLoggedIn(Bundle savedInstanceState) {
        setContentView(R.layout.activity_listener);

        bgView = findViewById(R.id.background);

        startBtn = findViewById(R.id.copy_db);
        startBtn.setOnClickListener(this::copyDb);
        startBtn.setEnabled(true);
    }

    private void copyDb(@NonNull View ignore) {
        startBtn.setEnabled(false);
        ListenerService.get().copyDb(this::updateState, this::setCopier);
    }

    private void updateState(@NonNull ReplicatorChange change) {
        final ReplicatorActivityLevel replState = change.getStatus().getActivityLevel();
        bgView.setBackgroundColor(getColorForReplicatorState(replState));
        if (!((replState == ReplicatorActivityLevel.CONNECTING) || (replState == ReplicatorActivityLevel.BUSY))) {
            setCopier(null);
        }
    }

    private void setCopier(@Nullable ListenerService.DBCopier newCopier) {
        final ListenerService.DBCopier oldCopier = copier.getAndSet(newCopier);
        if (oldCopier != null) { oldCopier.close(); }
        startBtn.setEnabled(newCopier == null);
    }
}
