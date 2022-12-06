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

import androidx.annotation.Nullable;

import java.util.function.Consumer;

import com.couchbase.lite.Document;
import com.couchbase.todo.service.DatabaseService;


public class GetListOwnerTask extends Scheduler.BackgroundTask<String, Boolean> {
    private final Consumer<Boolean> receiver;

    public GetListOwnerTask(Consumer<Boolean> receiver) { this.receiver = receiver; }

    @Override
    protected Boolean doInBackground(@Nullable String listId) {
        if (listId == null) { return false; }
        final DatabaseService dao = DatabaseService.get();
        final String user = dao.getUsername();
        final Document list = dao.fetchDoc(DatabaseService.COLLECTION_LISTS, listId);
        final Document moderator = dao.fetchDoc(DatabaseService.COLLECTION_LISTS, "moderator." + user);
        return (list != null) && (user.equals(list.getString("owner")) || (moderator != null));
    }

    @Override
    protected void onComplete(@Nullable Boolean isOwner) { receiver.accept((isOwner != null) && isOwner); }
}
