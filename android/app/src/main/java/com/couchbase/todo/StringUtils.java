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
package com.couchbase.todo;

import androidx.annotation.NonNull;

import java.util.Locale;
import java.util.Random;


public final class StringUtils {
    private StringUtils() { }

    public static final String ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    public static final String NUMERIC = "0123456789";
    public static final String ALPHANUMERIC = NUMERIC + ALPHA + ALPHA.toLowerCase(Locale.ROOT);
    private static final char[] CHARS = ALPHANUMERIC.toCharArray();

    @NonNull
    public static final ThreadLocal<Random> RANDOM = new ThreadLocal<>() {
        @NonNull
        protected synchronized Random initialValue() { return new Random(); }
    };

    @NonNull
    public static String getUniqueName(@NonNull String prefix, int len) { return prefix + '_' + randomString(len); }

    @NonNull
    public static String randomString(int len) {
        final char[] buf = new char[len];
        for (int idx = 0; idx < buf.length; ++idx) { buf[idx] = CHARS[RANDOM.get().nextInt(CHARS.length)]; }
        return new String(buf);
    }
}