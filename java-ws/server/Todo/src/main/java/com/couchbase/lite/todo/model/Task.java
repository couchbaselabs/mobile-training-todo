package com.couchbase.lite.todo.model;

import com.couchbase.lite.*;
import com.couchbase.lite.todo.support.ResponseException;
import com.couchbase.lite.todo.support.UserContext;
import com.couchbase.lite.todo.util.Preconditions;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

public class Task {
    static final String TYPE = "task";
    static final String KEY_TYPE = "type";
    static final String KEY_TASK = "task";
    static final String KEY_COMPLETE = "complete";
    static final String KEY_IMAGE = "image";
    static final String KEY_CREATED_AT = "createdAt";
    static final String KEY_OWNER = "owner";
    static final String KEY_TASK_LIST = "taskList";
    static final String KEY_TASK_LIST_ID = "id";
    static final String KEY_TASK_LIST_OWNER = "owner";

    private String id;

    private String task;

    private boolean complete;

    private Map<String, Object> image;

    private Date createdAt;

    private String owner;

    private TaskList taksList;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTask() {
        return task;
    }

    public void setTask(String task) {
        this.task = task;
    }

    public boolean isComplete() {
        return complete;
    }

    public void setComplete(boolean complete) {
        this.complete = complete;
    }

    public Map<String, Object> getImage() {
        return image;
    }

    public void setImage(Map<String, Object> image) {
        this.image = image;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }

    public TaskList getTaksList() {
        return taksList;
    }

    public void setTaksList(TaskList taksList) {
        this.taksList = taksList;
    }

    public static String create(UserContext context, String taskListId, Task task) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(task, "task");
        Preconditions.checkArgNotNull(task.getTask(), "task name");

        Database db = context.getDatabase();
        String username = context.getUsername();

        Document taskList =  db.getDocument(taskListId);
        if (taskList == null) { throw ResponseException.NOT_FOUND("task list id : " + taskListId); }

        MutableDocument doc = new MutableDocument();
        doc.setValue(KEY_TYPE, Task.TYPE);
        doc.setValue(KEY_TASK, task.getTask());
        doc.setValue(KEY_COMPLETE, task.isComplete());
        doc.setValue(KEY_OWNER, username);
        doc.setValue(KEY_CREATED_AT, new Date());

        MutableDictionary taskListInfo = new MutableDictionary();
        taskListInfo.setValue(KEY_TASK_LIST_ID, taskList.getId());
        taskListInfo.setValue(KEY_TASK_LIST_OWNER, taskList.getValue("owner"));
        doc.setValue(KEY_TASK_LIST, taskListInfo);
        db.save(doc);
        return doc.getId();
    }

    public static void update(UserContext context, String taskListId, String taskId, Task task) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");
        Preconditions.checkArgNotNull(task, "task");
        Preconditions.checkArgNotNull(task.getTask(), "task name");

        Database db = context.getDatabase();
        Document doc =  db.getDocument(taskId);
        if (doc == null) { throw ResponseException.NOT_FOUND("task id : " + taskId); }

        Dictionary taskList = doc.getDictionary(KEY_TASK_LIST);
        if (!taskListId.equals(taskList.getString(KEY_TASK_LIST_ID))) {
            throw ResponseException.BAD_REQUEST("Invalid task list id: " + taskListId);
        }

        MutableDocument mdoc = doc.toMutable();
        mdoc.setValue(KEY_TASK, task.task);
        mdoc.setValue(KEY_COMPLETE, task.isComplete());
        db.save(mdoc);
    }

    public static void delete(UserContext context, String taskId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskId, "taskId");

        Database db = context.getDatabase();
        Document doc =  db.getDocument(taskId);
        if (doc != null) {
            db.delete(doc);
        }
    }

    public static void updateImage(UserContext context,
                                   String taskListId,
                                   String taskId,
                                   InputStream is,
                                   String contentType) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");
        Preconditions.checkArgNotNull(is, "photo");
        Preconditions.checkArgNotNull(contentType, "content-type");

        Database db = context.getDatabase();
        Document doc =  db.getDocument(taskId);
        if (doc == null) { throw ResponseException.NOT_FOUND("task id : " + taskId); }

        Dictionary taskList = doc.getDictionary(KEY_TASK_LIST);
        if (!taskListId.equals(taskList.getString(KEY_TASK_LIST_ID))) {
            throw ResponseException.BAD_REQUEST("Invalid task list id: " + taskListId);
        }

        Blob blob = new Blob(contentType, is);
        MutableDocument mdoc = doc.toMutable();
        mdoc.setValue(KEY_IMAGE, blob);
        db.save(mdoc);
    }

    public static void deleteImage(UserContext context, String taskListId, String taskId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");

        Database db = context.getDatabase();
        Document doc =  db.getDocument(taskId);
        if (doc == null) { throw ResponseException.NOT_FOUND("task id : " + taskId); }

        MutableDocument mdoc = doc.toMutable();
        mdoc.setValue(KEY_IMAGE, null);
        db.save(mdoc);
    }

    public static Blob getPhoto(UserContext context, String taskListId, String taskId) {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(taskId, "taskId");

        Database db = context.getDatabase();
        Document doc =  db.getDocument(taskId);
        if (doc == null) { throw ResponseException.NOT_FOUND("task id : " + taskId); }

        Blob blob = doc.getBlob(KEY_IMAGE);
        if (blob == null) { throw ResponseException.NOT_FOUND("image"); }
        return blob;
    }

    public static List<Task> getTasks(UserContext context, String taskListId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");

        Database database = context.getDatabase();
        Query query = QueryBuilder
                .select(SelectResult.expression(Meta.id),
                        SelectResult.property(KEY_TASK),
                        SelectResult.property(KEY_COMPLETE),
                        SelectResult.property(KEY_IMAGE),
                        SelectResult.property(KEY_OWNER),
                        SelectResult.property(KEY_CREATED_AT),
                        SelectResult.property(KEY_TASK_LIST))
                .from(DataSource.database(database))
                .where(Expression.property(KEY_TYPE).equalTo(Expression.string(Task.TYPE))
                        .and(Expression.property(KEY_TASK_LIST + "." + KEY_TASK_LIST_ID)
                                .equalTo(Expression.string(taskListId))))
                .orderBy(Ordering.property(KEY_CREATED_AT), Ordering.property(KEY_TASK));

        List<Task> tasks = new ArrayList<>();
        ResultSet rs = query.execute();
        for (Result r : rs) {
            Task task = new Task();
            task.setId(r.getString(0));
            task.setTask(r.getString(1));
            task.setComplete(r.getBoolean(2));

            Blob image = r.getBlob(3);
            if (image != null) {
                task.image = image.getProperties();
            }

            task.setOwner(r.getString(4));
            task.setCreatedAt(r.getDate(5));
            Dictionary taskListDict = r.getDictionary(6);
            TaskList taskList = new TaskList();
            taskList.setId(taskListDict.getString(KEY_TASK_LIST_ID));
            taskList.setOwner(taskListDict.getString(KEY_TASK_LIST_OWNER));
            task.setTaksList(taskList);

            tasks.add(task);
        }
        return tasks;
    }
}
