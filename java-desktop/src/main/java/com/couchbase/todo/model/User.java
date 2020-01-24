package com.couchbase.todo.model;

import org.jetbrains.annotations.NotNull;

public class User {

    private @NotNull String id;

    private @NotNull String name;

    public User(String id, String name) {
        this.id = id;
        this.name = name;
    }

    @NotNull
    public String getId() {
        return id;
    }

    @NotNull
    public String getName() {
        return name;
    }

}
