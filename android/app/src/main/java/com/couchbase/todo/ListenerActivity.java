package com.couchbase.todo;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.todo.listener.Listener;


public class ListenerActivity extends ToDoActivity {
    private static final String TAG = "LISTEN_ACT";

    public static void start(@NonNull Activity act) { act.startActivity(new Intent(act, ListenerActivity.class)); }

    private View bgView;
    private FloatingActionButton startBtn;

    private Listener.DBCopier copier;


    @Override
    protected void onCreateLoggedIn(Bundle savedInstanceState) {
        setContentView(R.layout.activity_listener);

        bgView = findViewById(R.id.background);

        startBtn = findViewById(R.id.copy_db);
        startBtn.setOnClickListener(this::copyDb);
        startBtn.setEnabled(true);
    }

    private void copyDb(View ignore) {
        startBtn.setEnabled(false);
        Listener.get().copyDb(this::updateState, this::setCopier);
    }

    private void updateState(ReplicatorActivityLevel replState) {
        bgView.setBackgroundColor(getColorForReplicatorState(replState));
        if (!((replState == ReplicatorActivityLevel.CONNECTING) || (replState == ReplicatorActivityLevel.BUSY))) {
            setCopier(null);
        }
    }

    private void setCopier(Listener.DBCopier newCopier) {
        if (copier != null) { copier.close(); }
        copier = newCopier;
        startBtn.setEnabled(copier == null);
    }
}
