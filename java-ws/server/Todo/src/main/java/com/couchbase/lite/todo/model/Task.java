package com.couchbase.lite.todo.model;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Dictionary;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.todo.support.ResponseException;
import com.couchbase.lite.todo.support.UserContext;
import com.couchbase.lite.todo.util.Preconditions;


public class Task {
    public static final String COLLECTION_TASKS = "tasks";

    private static final String KEY_TASK = "task";
    private static final String KEY_COMPLETE = "complete";
    private static final String KEY_IMAGE = "image";
    private static final String KEY_CREATED_AT = "createdAt";
    private static final String KEY_OWNER = "owner";
    private static final String KEY_TASK_LIST = "taskList";
    private static final String KEY_TASK_LIST_ID = "id";
    private static final String KEY_TASK_LIST_OWNER = "owner";


    public static String create(UserContext context, String taskListId, Task task) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(task, "task");
        Preconditions.checkArgNotNull(task.getTask(), "task name");

        Document taskList = context.getDataSource(TaskList.COLLECTION_LISTS).getDocument(taskListId);
        if (taskList == null) { throw ResponseException.notFound("task list id : " + taskListId); }

        MutableDocument doc = new MutableDocument();
        doc.setValue(KEY_TASK, task.getTask());
        doc.setValue(KEY_COMPLETE, task.isComplete());
        doc.setValue(KEY_OWNER, context.getUsername());
        doc.setValue(KEY_CREATED_AT, new Date());

        MutableDictionary taskListInfo = new MutableDictionary();
        taskListInfo.setValue(KEY_TASK_LIST_ID, taskList.getId());
        taskListInfo.setValue(KEY_TASK_LIST_OWNER, taskList.getValue("owner"));
        doc.setValue(KEY_TASK_LIST, taskListInfo);

        Collection collection = context.getDataSource(COLLECTION_TASKS);
        collection.save(doc);
        System.out.println("TASK: New task: " + collection.getDocument(doc.getId()).toJSON());

        return doc.getId();
    }

    public static void update(UserContext context, String taskListId, String taskId, Task task)
        throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");
        Preconditions.checkArgNotNull(task, "task");
        Preconditions.checkArgNotNull(task.getTask(), "task name");

        Collection collection = context.getDataSource(COLLECTION_TASKS);
        Document doc = collection.getDocument(taskId);
        if (doc == null) { throw ResponseException.notFound("task id : " + taskId); }

        Dictionary taskList = doc.getDictionary(KEY_TASK_LIST);
        if (!taskListId.equals(taskList.getString(KEY_TASK_LIST_ID))) {
            throw ResponseException.badRequest("Invalid task list id: " + taskListId);
        }

        MutableDocument mdoc = doc.toMutable();
        mdoc.setValue(KEY_TASK, task.task);
        mdoc.setValue(KEY_COMPLETE, task.isComplete());

        collection.save(mdoc);
        System.out.println("TASK: New task: " + collection.getDocument(mdoc.getId()).toJSON());
    }

    public static void delete(UserContext context, String taskId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskId, "taskId");

        Collection collection = context.getDataSource(COLLECTION_TASKS);
        Document doc = collection.getDocument(taskId);
        if (doc != null) { collection.delete(doc); }

        System.out.println("TASK: Deleted task: " + doc.toJSON());
    }

    public static void updateImage(
        UserContext context,
        String taskListId,
        String taskId,
        InputStream is,
        String contentType) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");
        Preconditions.checkArgNotNull(is, "photo");
        Preconditions.checkArgNotNull(contentType, "content-type");

        Collection collection = context.getDataSource(COLLECTION_TASKS);
        Document doc = collection.getDocument(taskId);
        if (doc == null) { throw ResponseException.notFound("task id : " + taskId); }

        Dictionary taskList = doc.getDictionary(KEY_TASK_LIST);
        if (!taskListId.equals(taskList.getString(KEY_TASK_LIST_ID))) {
            throw ResponseException.badRequest("Invalid task list id: " + taskListId);
        }

        Blob blob = new Blob(contentType, is);
        MutableDocument mdoc = doc.toMutable();
        mdoc.setValue(KEY_IMAGE, blob);
        collection.save(mdoc);
    }

    public static void deleteImage(UserContext context, String taskListId, String taskId)
        throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");

        Collection collection = context.getDataSource(COLLECTION_TASKS);
        Document doc = collection.getDocument(taskId);
        if (doc == null) { throw ResponseException.notFound("task id : " + taskId); }

        MutableDocument mdoc = doc.toMutable();
        mdoc.setValue(KEY_IMAGE, null);
        collection.save(mdoc);
    }

    public static Blob getPhoto(UserContext context, String taskListId, String taskId)
        throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");

        Collection collection = context.getDataSource(COLLECTION_TASKS);
        Document doc = collection.getDocument(taskId);
        if (doc == null) { throw ResponseException.notFound("task id : " + taskId); }

        Blob blob = doc.getBlob(KEY_IMAGE);
        if (blob == null) { throw ResponseException.notFound("image"); }

        return blob;
    }

    public static List<Task> getTasks(UserContext context, String taskListId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");

        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property(KEY_TASK),
                SelectResult.property(KEY_COMPLETE),
                SelectResult.property(KEY_IMAGE),
                SelectResult.property(KEY_OWNER),
                SelectResult.property(KEY_CREATED_AT),
                SelectResult.property(KEY_TASK_LIST))
            .from(DataSource.collection(context.getDataSource(COLLECTION_TASKS)))
            .where(Expression.property(KEY_TASK_LIST + "." + KEY_TASK_LIST_ID)
                .equalTo(Expression.string(taskListId)))
            .orderBy(Ordering.property(KEY_CREATED_AT), Ordering.property(KEY_TASK));

        List<Task> tasks = new ArrayList<>();
        try (ResultSet rs = query.execute()) {
            for (Result r: rs) {
                Task task = new Task();
                task.setId(r.getString(0));
                task.setTask(r.getString(1));
                task.setComplete(r.getBoolean(2));

                Blob image = r.getBlob(3);
                if (image != null) { task.image = image.getProperties(); }

                task.setOwner(r.getString(4));
                task.setCreatedAt(r.getDate(5));
                Dictionary taskListDict = r.getDictionary(6);
                TaskList taskList = new TaskList();
                taskList.setId(taskListDict.getString(KEY_TASK_LIST_ID));
                taskList.setOwner(taskListDict.getString(KEY_TASK_LIST_OWNER));
                task.setTaskList(taskList);

                tasks.add(task);

                System.out.println("TASK: found: " + task);
            }
        }

        return tasks;
    }


    private String id;
    private String task;
    private boolean complete;
    private Map<String, Object> image;
    private Date createdAt;
    private String owner;
    private TaskList taskList;

    public String getId() { return id; }

    public void setId(String id) { this.id = id; }

    public String getTask() { return task; }

    public void setTask(String task) { this.task = task; }

    public boolean isComplete() { return complete; }

    public void setComplete(boolean complete) { this.complete = complete; }

    public Map<String, Object> getImage() { return image; }

    public void setImage(Map<String, Object> image) { this.image = image; }

    public Date getCreatedAt() { return createdAt; }

    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public String getOwner() { return owner; }

    public void setOwner(String owner) { this.owner = owner; }

    public TaskList getTaskList() { return taskList; }

    public void setTaskList(TaskList taskList) { this.taskList = taskList; }

    public String toString() { return "TASK@" + id + "{" + taskList.getName() + ": " + task + ", " + owner + "}"; }
}
