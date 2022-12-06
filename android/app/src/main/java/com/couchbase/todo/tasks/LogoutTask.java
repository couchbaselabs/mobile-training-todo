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

import com.couchbase.lite.Database;
import com.couchbase.todo.service.DatabaseService;


public class LogoutTask extends Scheduler.BackgroundTask<Database, Void> {
    private final DatabaseService dbService;
    private final boolean deleting;

    public LogoutTask(@NonNull DatabaseService dbService, boolean deleting) {
        this.dbService = dbService;
        this.deleting = deleting;
    }

    @Override
    protected Void doInBackground(@Nullable Database db) {
        if (db != null) { dbService.logoutSafely(db, deleting); }
        return null;
    }
}
