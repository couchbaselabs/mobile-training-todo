package com.couchbase.lite.todo.model;

import com.couchbase.lite.*;
import com.couchbase.lite.todo.support.ResponseException;
import com.couchbase.lite.todo.support.UserContext;
import com.couchbase.lite.todo.util.Preconditions;

import java.util.ArrayList;
import java.util.List;


public class TaskListUser {
    private static final String TYPE = "task-list.user";
    private static final String KEY_TYPE = "type";
    private static final String KEY_USERNAME = "username";
    private static final String KEY_TASK_LIST = "taskList";
    private static final String KEY_TASK_LIST_ID = "id";
    private static final String KEY_TASK_LIST_OWNER = "owner";

    private String id;

    private String name;

    private TaskList taksList;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public TaskList getTaksList() {
        return taksList;
    }

    public void setTaksList(TaskList taksList) {
        this.taksList = taksList;
    }

    public static String add(UserContext context, String taskListId, TaskListUser user) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(user, "user");
        Preconditions.checkArgNotNull(user.getName(), "username");

        Database db = context.getDatabase();

        Document taskList = db.getDocument(taskListId);
        if (taskList == null) { throw ResponseException.NOT_FOUND("task list id : " + taskListId); }

        String docId = taskListId + "." + user.getName();
        if (db.getDocument(docId) != null) {
            throw ResponseException.BAD_REQUEST("User " + user.getName() + " has been added.");
        }

        MutableDocument doc = new MutableDocument(docId);
        doc.setValue(KEY_TYPE, TYPE);
        doc.setValue(KEY_USERNAME, user.getName());

        MutableDictionary taskListInfo = new MutableDictionary();
        taskListInfo.setValue(KEY_TASK_LIST_ID, taskList.getId());
        taskListInfo.setValue(KEY_TASK_LIST_OWNER, taskList.getValue("owner"));
        doc.setValue(KEY_TASK_LIST, taskListInfo);
        db.save(doc);

        System.out.println("Current List Document to JSON (when add user): " + taskList.toJSON());

        return doc.getId();
    }

    public static void delete(UserContext context, String userId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(userId, "user id");

        Database db = context.getDatabase();
        Document doc = db.getDocument(userId);
        if (doc != null) {
            db.delete(doc);
        }
    }

    public static List<TaskListUser> getUsers(UserContext context, String taskListId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");

        Database database = context.getDatabase();
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property(KEY_USERNAME),
                SelectResult.property(KEY_TASK_LIST))
            .from(DataSource.database(database))
            .where(Expression.property(KEY_TYPE).equalTo(Expression.string(TaskListUser.TYPE))
                .and(Expression.property(KEY_TASK_LIST + "." + KEY_TASK_LIST_ID)
                    .equalTo(Expression.string(taskListId))))
            .orderBy(Ordering.property(KEY_USERNAME));

        List<TaskListUser> users = new ArrayList<>();
        ResultSet rs = query.execute();
        for (Result r: rs) {
            TaskListUser user = new TaskListUser();
            user.setId(r.getString(0));
            user.setName(r.getString(1));

            Dictionary taskListDict = r.getDictionary(2);
            TaskList taskList = new TaskList();
            taskList.setId(taskListDict.getString(KEY_TASK_LIST_ID));
            taskList.setOwner(taskListDict.getString(KEY_TASK_LIST_OWNER));
            user.setTaksList(taskList);

            users.add(user);

            System.out.println("Query result to JSON (when add user to a list) : " + r.toJSON());
        }
        return users;
    }
}
