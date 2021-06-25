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
package com.couchbase.todo.db;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.text.DateFormat;
import java.util.Date;

import com.couchbase.lite.Conflict;
import com.couchbase.lite.ConflictResolver;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.config.Config;


public class SimpleConflictResolver implements ConflictResolver {
    public static final String KEY_CONFLICT = "conflict";

    private static final ThreadLocal<DateFormat> formatter = new ThreadLocal<DateFormat>() {
        @Override
        protected DateFormat initialValue() { return DateFormat.getDateTimeInstance(); }
    };


    @Nullable
    @Override
    public Document resolve(@NonNull Conflict conflict) {
        // deletion always wins.
        final Document localDoc = conflict.getLocalDocument();
        final Document remoteDoc = conflict.getRemoteDocument();
        if ((localDoc == null) || (remoteDoc == null)) { return null; }

        final Document winner;
        switch (Config.get().getCcrState()) {
            case LOCAL:
                winner = localDoc;
                break;
            case REMOTE:
                winner = remoteDoc;
                break;
            default:
                // shouldn't happen: use default strategy
                final String localRevId = localDoc.getRevisionID();
                final String remoteRevId = remoteDoc.getRevisionID();
                winner = ((remoteRevId == null) || ((localRevId != null) && (localRevId.compareTo(remoteRevId) > 0)))
                    ? localDoc
                    : remoteDoc;
        }

        final MutableDocument doc = winner.toMutable();
        doc.setString(
            KEY_CONFLICT,
            "@ " + formatter.get().format(new Date()) + ((winner == remoteDoc) ? ": remote" : ": local"));

        return doc;
    }
}
