package com.couchbase.todo.model;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.lite.Blob;


public class Task {
    @NotNull
    private final String id;

    @NotNull
    private final String name;

    private final boolean complete;

    @Nullable
    private final Blob image;

    public Task(@NotNull String id, @NotNull String name, boolean complete, @Nullable Blob image) {
        this.id = id;
        this.name = name;
        this.image = image;
        this.complete = complete;
    }

    @NotNull
    public String getId() { return id; }

    @NotNull
    public String getName() { return name; }

    public boolean isComplete() { return complete; }

    @Nullable
    public Blob getImage() { return image; }
}
