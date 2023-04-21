package com.couchbase.todo.model;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;


public class TaskList {
    @Nullable
    public static TaskList create(@Nullable String id, @Nullable String name, @Nullable String owner) {
        return ((id == null) || (name == null) || (owner == null))
            ? null
            : new TaskList(id, name, owner);
    }


    @NotNull
    private final String id;
    @NotNull
    private final String name;
    @NotNull
    private final String owner;
    private final int todo;

    public TaskList(@NotNull String id, @NotNull String name, @NotNull String owner) {
        this.id = id;
        this.name = name;
        this.owner = owner;
        this.todo = 0;
    }

    public TaskList(TaskList taskList, int todo) {
        this.id = taskList.id;
        this.name = taskList.name;
        this.owner = taskList.owner;
        this.todo = todo;
    }

    @NotNull
    public String getId() { return id; }

    @NotNull
    public String getName() { return name; }

    @NotNull
    public String getOwner() { return owner; }

    public int getTodo() { return todo; }

    @Override
    public String toString() { return "TaskList{" + id + ", " + name + ", " + owner + ", " + todo + "}"; }
}
