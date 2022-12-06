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

import java.util.Arrays;

import com.couchbase.todo.service.DatabaseService;


public class LoginTask extends Scheduler.BackgroundTask<Void, Void> {
    @NonNull
    private final String username;
    @NonNull
    private final char[] password;
    @Nullable
    private Runnable onLogin;

    public LoginTask(@NonNull Runnable onLogin, @NonNull String username, @NonNull char[] password) {
        this.onLogin = onLogin;
        this.username = username;
        this.password = password;
    }

    // args are username, password
    @Override
    protected Void doInBackground(@Nullable Void ignore) {
        DatabaseService.get().login(username, password);
        Arrays.fill(password, ' ');
        return null;
    }

    @Override
    protected void onCancelled(@Nullable Exception ignore) { onLogin = null; }

    @Override
    protected void onComplete(@Nullable Void ignore) {
        if (onLogin != null) { onLogin.run(); }
    }
}
