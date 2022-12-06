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
package com.couchbase.todo.app;

import android.app.Application;
import android.util.Log;

import androidx.annotation.GuardedBy;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.tasks.Scheduler;


public class ToDo extends Application {
    private static final String TAG = "APP";

    public interface Listener {
        void onError(Exception err);
        void onNewReplicatorState(ReplicatorActivityLevel state);
    }

    private static ToDo todoApp;

    public static ToDo get() { return todoApp; }

    public static void setApp(ToDo app) { todoApp = app; }


    @GuardedBy("this")
    @NonNull
    private ReplicatorActivityLevel replicatorState = ReplicatorActivityLevel.STOPPED;
    @GuardedBy("this")
    @NonNull
    private List<Exception> appErrors = new ArrayList<>();
    @Nullable
    @GuardedBy("this")
    private Listener appListener;

    @Override
    public void onCreate() {
        super.onCreate();

        setApp(this);

        CouchbaseLite.init(this);

        // warm up the DAO
        DatabaseService.get();
    }

    @Override
    public void onTerminate() {
        DatabaseService.get().forceLogout();
        super.onTerminate();
    }

    public void registerListener(@Nullable Listener listener) {
        final List<Exception> errors;
        final ReplicatorActivityLevel state;
        synchronized (this) {
            if (Objects.equals(appListener, listener)) { return; }

            appListener = listener;
            if (appListener == null) { return; }

            errors = appErrors;
            appErrors = new ArrayList<>();

            state = replicatorState;
        }

        final Scheduler scheduler = Scheduler.get();
        for (Exception err: errors) { scheduler.deliverError(listener, err); }
        scheduler.deliverNewState(listener, state);
    }

    public void reportError(@NonNull Throwable err) {
        final Listener listener;

        if (!(err instanceof Exception)) {
            Scheduler.get().fail(err);
            return;
        }

        final Exception e = (Exception) err;

        synchronized (this) {
            listener = appListener;
            if (listener == null) {
                appErrors.add(e);
                return;
            }
        }

        Log.w(TAG, "DB error", err);
        Scheduler.get().deliverError(listener, e);
    }

    public void updateReplicatorState(@NonNull ReplicatorActivityLevel state) {
        final Listener listener;
        synchronized (this) {
            listener = appListener;
            replicatorState = state;
        }

        if (listener != null) { Scheduler.get().deliverNewState(listener, state); }
    }
}
