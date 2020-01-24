package com.couchbase.todo.model;

import org.jetbrains.annotations.NotNull;

public class TaskList {

    private @NotNull String id;

    private @NotNull String name;

    private @NotNull String owner;

    public TaskList(String id, String name, String owner) {
        this.id = id;
        this.name = name;
        this.owner = owner;
    }

    @NotNull
    public String getId() {
        return id;
    }

    @NotNull
    public String getName() {
        return name;
    }

    @NotNull
    public String getOwner() {
        return owner;
    }

}
