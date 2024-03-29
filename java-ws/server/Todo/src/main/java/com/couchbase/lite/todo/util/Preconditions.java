package com.couchbase.lite.todo.util;

import com.couchbase.lite.todo.support.ResponseException;

public class Preconditions {
    private Preconditions() {}

    public static void checkArgNotNull(Object obj, String name) {
        if (obj == null) { throw ResponseException.badRequest(name + " cannot be null"); }
    }
}
