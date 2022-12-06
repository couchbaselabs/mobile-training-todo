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

import androidx.annotation.Nullable;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;


public class UpdateTaskCompletedTask extends Scheduler.BackgroundTask<Boolean, Void> {
    private static final String TAG = "TASK_UPD_TASK_COMPLETE";
    private final String taskId;

    public UpdateTaskCompletedTask(String taskId) { this.taskId = taskId; }

    @Override
    protected Void doInBackground(@Nullable Boolean complete) {
        final Document doc = DatabaseService.get().fetchDoc(DatabaseService.COLLECTION_TASKS, taskId);
        if (doc == null) {
            Log.w(TAG, "Attempt to update non-existent document: " + taskId);
            return null;
        }

        final MutableDocument task = doc.toMutable();
        task.setBoolean("complete", (complete != null) && complete);
        DatabaseService.get().saveDoc(DatabaseService.COLLECTION_TASKS, task);

        return null;
    }
}
