package com.couchbase.todo.model;

import org.jetbrains.annotations.NotNull;


public class TaskList {
    public static class Builder {
        private String id;
        private String name;
        private String owner;
        private int numIncomplete;

        public TaskList.Builder id(String id) {
            this.id = id;
            return this;
        }

        public TaskList.Builder name(String name) {
            this.name = name;
            return this;
        }

        public TaskList.Builder owner(String owner) {
            this.owner = owner;
            return this;
        }

        public TaskList.Builder numIncomplete(int numIncomplete) {
            this.numIncomplete = numIncomplete;
            return this;
        }

        public TaskList build() {
            return new TaskList(this);
        }
    }

    public static Builder builder() { return new TaskList.Builder(); }

    private @NotNull String id;

    private @NotNull String name;

    private @NotNull String owner;

    private @NotNull int numIncomplete;


    private TaskList(TaskList.Builder builder) {
        this.id = builder.id;
        this.name = builder.name;
        this.owner = builder.owner;
        this.numIncomplete = builder.numIncomplete;
    }

    @NotNull
    public String getId() { return id; }

    @NotNull
    public String getName() { return name; }

    @NotNull
    public String getOwner() { return owner; }

    @NotNull
    public int getNumIncomplete() { return numIncomplete; }
}
