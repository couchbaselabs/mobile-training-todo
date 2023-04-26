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

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;


public class CreateTaskTask extends Scheduler.BackgroundTask<String, Void> {
    private final String TAG = "TASK_NEW_TASK";

    private final String listId;

    public CreateTaskTask(@NonNull String listId) { this.listId = listId; }

    @Override
    protected Void doInBackground(@Nullable String title) {
        final MutableDocument mDoc = new MutableDocument()
            .setDate("createdAt", new Date())
            .setString("task", title)
            .setValue("owner", DatabaseService.get().getUsername())
            .setBoolean("complete", false);

        String owner = null;
        final Document taskList = DatabaseService.get().fetchDoc(DatabaseService.COLLECTION_LISTS, listId);
        if (taskList != null) { owner = taskList.getString("owner"); }
        if (owner == null) {
            Log.w(TAG, "Creating orphan task: " + title + " in " + listId);
            owner = "?";
        }

        final Map<String, Object> taskListInfo = new HashMap<>();
        taskListInfo.put("id", listId);
        taskListInfo.put("owner", owner);
        mDoc.setValue("taskList", taskListInfo);

        DatabaseService.get().saveDoc(DatabaseService.COLLECTION_TASKS, mDoc);

        return null;
    }
}
