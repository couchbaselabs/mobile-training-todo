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

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;

import okhttp3.Credentials;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.service.DatabaseService;
import com.couchbase.todo.service.ReplicatorService;


public class CreateListTask extends SaveDocTask {
    private static final String TAG = "CREATE_LIST";

    private static final String REQ_BODY_BEGIN = "{\"name\":\"lists.";
    private static final String REQ_BODY_END = (
        ".contributor\","
            + "\"collection_access\": {"
            + "     \"_default\": {"
            + "         \"lists\": {\"admin_channels\": []},"
            + "         \"tasks\": {\"admin_channels\": []},"
            + "         \"users\": {\"admin_channels\": []}"
            + "      }"
            + "  }"
            + "}")
        .replace(" ", "");


    public CreateListTask() { super(DatabaseService.COLLECTION_LISTS); }

    @Nullable
    @Override
    protected Document doInBackground(@Nullable MutableDocument doc) {
        if (doc == null) {
            Log.i(TAG, "Called with null doc");
            return null;
        }

        final URI sgUri = ReplicatorService.get().getReplicationUri();
        if (sgUri == null) { return null; }

        final String adminUri = "http://" + sgUri.getHost() + ":4985/todo/_role/";
        final URL sgAdminUrl;
        try { sgAdminUrl = new URL(adminUri); }
        catch (MalformedURLException e) {
            Log.e(TAG, "Cannot create SGW Admin URI: " + adminUri, e);
            return null;
        }

        final Request request = new Request.Builder()
            .url(sgAdminUrl)
            .addHeader("Authorization", Credentials.basic("admin", "password"))
            .post(RequestBody.create(MediaType.parse("application/json"), REQ_BODY_BEGIN + doc.getId() + REQ_BODY_END))
            .build();

        Log.v(TAG, "Creating role for list " + doc.getString("name") + "@" + doc.getString("owner") + ": " + request);
        try (Response response = new OkHttpClient.Builder().build().newCall(request).execute()) {
            // 409 is CONFLICT, which means the role already exists
            if (!response.isSuccessful() && (409 != response.code())) {
                Log.w(TAG, "List creation admin request failed: " + response);
                return null;
            }
        }
        catch (IOException e) {
            Log.d(TAG, "List creation admin request failed", e);
            return null;
        }

        return super.doInBackground(doc);
    }
}
