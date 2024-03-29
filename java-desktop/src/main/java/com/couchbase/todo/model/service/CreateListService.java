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
package com.couchbase.todo.model.service;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;

import javafx.concurrent.Service;
import javafx.concurrent.Task;
import okhttp3.Credentials;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Document;
import com.couchbase.lite.MutableDocument;
import com.couchbase.todo.Logger;
import com.couchbase.todo.controller.MainController;
import com.couchbase.todo.model.DB;


public class CreateListService extends Service<Document> {
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


    private final MutableDocument document;

    public CreateListService(MutableDocument document) {
        this.document = document;
        setExecutor(DB.get().getExecutor());
    }

    @Override
    protected Task<Document> createTask() {
        Logger.log("Create List Task");
        return new Task<>() {
            @Override
            protected Document call() throws CouchbaseLiteException {
                if (document == null) { return null; }

                final URI sgUri = DB.getReplicationUri();
                if (sgUri == null) { return null; }

                final String adminUri = "http://" + sgUri.getHost() + ":4985/todo/_role/";
                final URL sgAdminUrl;
                try { sgAdminUrl = new URL(adminUri); }
                catch (MalformedURLException e) {
                    Logger.log("Bad admin URL: " + adminUri, e);
                    return null;
                }

                final String body = REQ_BODY_BEGIN + document.getId() + REQ_BODY_END;
                if (MainController.JSON_BOOLEAN.get()) {
                    Logger.log("Creating role: " + adminUri + "\n" + body);
                }

                final Request request = new Request.Builder()
                    .url(sgAdminUrl)
                    .addHeader("Authorization", Credentials.basic("admin", "password"))
                    .post(RequestBody.create(
                        MediaType.parse("application/json"), body))
                    .build();

                try (Response response = new OkHttpClient.Builder().build().newCall(request).execute()) {
                    // 409 is CONFLICT, which means the role already exists
                    if (!response.isSuccessful() && (409 != response.code())) {
                        Logger.log("Create role request failed: " + response);
                        return null;
                    }
                }
                catch (IOException e) {
                    Logger.log("Create role request error", e);
                    return null;
                }

                return DB.get().saveDocument(DB.COLLECTION_LISTS, document);
            }
        };
    }
}
