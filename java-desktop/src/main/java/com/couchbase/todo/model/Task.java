package com.couchbase.todo.model;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.lite.Blob;

public class Task {

    private @NotNull String id;

    private @NotNull String name;

    private boolean complete;

    private @Nullable Blob image;

    public Task(String id, String name, boolean complete, Blob image) {
        this.id = id;
        this.name = name;
        this.image = image;
        this.complete = complete;
    }

    @NotNull
    public String getId() {
        return id;
    }

    @NotNull
    public String getName() {
        return name;
    }

    public boolean isComplete() {
        return complete;
    }

    @Nullable
    public Blob getImage() {
        return image;
    }

}
