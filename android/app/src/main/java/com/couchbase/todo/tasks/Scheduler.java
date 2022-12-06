//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
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
package com.couchbase.todo.tasks;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.WorkerThread;

import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.FutureTask;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.todo.app.ToDo;
import com.couchbase.todo.service.ConfigurationService;


public class Scheduler {
    @NonNull
    public static final ExecutorService EXECUTOR = Executors.newSingleThreadExecutor();

    @NonNull
    private static final AtomicReference<Scheduler> INSTANCE = new AtomicReference<>();

    @NonNull
    public static Scheduler get() {
        final Scheduler instance = INSTANCE.get();
        if (instance != null) { return instance; }
        INSTANCE.compareAndSet(null, new Scheduler());
        return INSTANCE.get();
    }

    public static void assertNotMainThread() {
        if (isUIThread()) { throw new IllegalStateException("DB operations must not be run on the UI thread"); }
    }

    public static void assertMainThread() {
        if (!isUIThread()) { throw new IllegalStateException("DB operations must not be run on the UI thread"); }
    }

    public static boolean isUIThread() { return Thread.currentThread().equals(Looper.getMainLooper().getThread()); }

    public abstract static class BackgroundTask<P, R> {
        private static final String TAG = "TASK";

        private final Handler handler;

        private final AtomicBoolean cancelled = new AtomicBoolean();
        private final AtomicReference<FutureTask<R>> future = new AtomicReference<>();

        public BackgroundTask() { this.handler = new Handler(Looper.getMainLooper()); }

        @MainThread
        public final void execute() { execute(null); }

        @MainThread
        public final void execute(@Nullable P param) {
            assertMainThread();

            final FutureTask<R> futureTask = new FutureTask<>(() -> doInBackground(param)) {
                protected void done() {
                    try {
                        R result = get();
                        if (!cancelled.get()) { postResult(result); }
                        else { postCancellation(); }
                    }
                    catch (CancellationException e) { postCancellation(); }
                    catch (InterruptedException e) {
                        Log.w(TAG, "Task execution interrupted", e);
                        postCancellation(e);
                    }
                    catch (ExecutionException e) {
                        final Throwable cause = e.getCause();
                        if ((cause == null) || (cause instanceof Exception)) {
                            postCancellation(e);
                            return;
                        }
                        Log.w(TAG, "Task execution failed catastrophically", e);
                        ToDo.get().reportError(e);
                        postCancellation();
                    }
                }
            };

            if (!future.compareAndSet(null, futureTask)) {
                throw new IllegalStateException("Attempt to execute a task twice");
            }

            EXECUTOR.execute(futureTask);
        }

        public final boolean cancel(boolean force) {
            cancelled.set(true);
            return future.get().cancel(force);
        }

        @MainThread
        public final boolean isCancelled() { return cancelled.get(); }

        @WorkerThread
        protected abstract R doInBackground(@Nullable P param) throws Exception;

        @MainThread
        protected void onCancelled(@Nullable Exception err) { }

        @MainThread
        protected void onComplete(@Nullable R result) { }

        private void postCancellation() { postCancellation(null); }

        private void postCancellation(@Nullable Exception err) {
            cancelled.set(true);
            handler.post(() -> onCancelled(err));
        }

        private void postResult(@Nullable R result) { handler.post(() -> onComplete(result)); }
    }


    @NonNull
    private final Handler mainHandler;

    private Scheduler() { mainHandler = new Handler(Looper.getMainLooper()); }

    // always deliver the error asynchronously, on the main thread
    public void fail(@NonNull Throwable err) {
        mainHandler.post(() -> { throw new RuntimeException(err); });
    }

    // always deliver the error asynchronously, on the main thread
    public void deliverError(@NonNull ToDo.Listener listener, @NonNull Exception err) {
        mainHandler.post(() -> listener.onError(err));
    }

    // always deliver state asynchronously, on the main thread
    public void deliverNewState(@NonNull ToDo.Listener listener, @NonNull ReplicatorActivityLevel state) {
        mainHandler.post(
            () -> listener.onNewReplicatorState((ConfigurationService.get().isSyncEnabled())
                ? state
                : ReplicatorActivityLevel.OFFLINE));
    }
}
