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
import android.content.Context;

import com.couchbase.lite.CouchbaseLite;
import com.couchbase.todo.db.DAO;


public class ToDo extends Application {
    private static final String TAG = "APP";

    private static Context appContext;

    public static Context getAppContext() { return appContext; }

    public static void setAppContext(Context context) { appContext = context; }

    @Override
    public void onCreate() {
        super.onCreate();

        setAppContext(this);

        CouchbaseLite.init(this);

        // warm up the DAO
        DAO.get();
    }

    @Override
    public void onTerminate() {
        DAO.get().forceLogout();
        super.onTerminate();
    }
}
