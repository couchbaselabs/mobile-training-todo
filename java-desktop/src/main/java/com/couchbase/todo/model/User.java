package com.couchbase.todo.model;

import org.jetbrains.annotations.NotNull;


public class User {
    @NotNull
    private final String id;

    @NotNull
    private final String name;

    public User(@NotNull String id, @NotNull String name) {
        this.id = id;
        this.name = name;
    }

    @NotNull
    public String getId() { return id; }

    @NotNull
    public String getName() { return name; }
}
