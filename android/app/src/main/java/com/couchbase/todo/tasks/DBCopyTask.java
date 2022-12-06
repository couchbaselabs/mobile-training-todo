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

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.function.Consumer;

import com.couchbase.lite.ReplicatorChangeListener;
import com.couchbase.todo.service.ListenerService;


public class DBCopyTask extends Scheduler.BackgroundTask<Void, ListenerService.DBCopier> {
    @NonNull
    private final ListenerService listener;
    @NonNull
    private final ReplicatorChangeListener replListener;
    @NonNull
    private final Consumer<ListenerService.DBCopier> receiver;

    public DBCopyTask(
        @NonNull ListenerService listener,
        @NonNull ReplicatorChangeListener replListener,
        @NonNull Consumer<ListenerService.DBCopier> receiver) {
        this.listener = listener;
        this.replListener = replListener;
        this.receiver = receiver;
    }

    @NonNull
    @Override
    protected ListenerService.DBCopier doInBackground(@Nullable Void ignore) { return listener.copyDb(replListener); }

    @Override
    protected void onComplete(@Nullable ListenerService.DBCopier copier) { receiver.accept(copier); }
}
