package com.couchbase.lite.todo.model;

import java.util.ArrayList;
import java.util.List;

import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
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


public class TaskListUser {
    public static final String COLLECTION_USERS = "users";

    private static final String KEY_USERNAME = "username";
    private static final String KEY_NAME = "name";
    private static final String KEY_TASK_LIST = "taskList";
    private static final String KEY_TASK_LIST_ID = "id";
    private static final String KEY_TASK_LIST_OWNER = "owner";
    public static final String KEY_PARENT_LIST_ID = "taskList.id";

    public static String add(UserContext context, String taskListId, TaskListUser user) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");
        Preconditions.checkArgNotNull(user, "user");
        Preconditions.checkArgNotNull(user.getName(), "username");

        Collection collection = context.getDataSource(TaskList.COLLECTION_LISTS);

        Document taskList = collection.getDocument(taskListId);
        if (taskList == null) { throw ResponseException.notFound("Task list: " + taskListId); }

        String username = user.getName();
        String listName = taskList.getString(KEY_NAME);

        String docId = taskListId + "." + username;
        if (collection.getDocument(docId) != null) { return docId; }

        MutableDocument doc = new MutableDocument(docId);
        doc.setValue(KEY_USERNAME, user.getName());

        MutableDictionary taskListInfo = new MutableDictionary();
        taskListInfo.setValue(KEY_TASK_LIST_ID, taskList.getId());
        taskListInfo.setValue(KEY_TASK_LIST_OWNER, taskList.getValue(KEY_TASK_LIST_OWNER));

        doc.setValue(KEY_TASK_LIST, taskListInfo);

        collection = context.getDataSource(COLLECTION_USERS);
        collection.save(doc);
        System.out.println("USER: Added user for list " + taskListId + ": " + collection.getDocument(docId).toJSON());

        return doc.getId();
    }

    public static void delete(UserContext context, String userId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(userId, "user id");

        Collection collection = context.getDataSource(COLLECTION_USERS);
        Document doc = collection.getDocument(userId);
        if (doc != null) { collection.delete(doc); }
        System.out.println("USER: Deleted user: " + doc.toJSON());
    }

    public static List<TaskListUser> getUsers(UserContext context, String taskListId) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(taskListId, "taskListId");

        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property(KEY_USERNAME),
                SelectResult.property(KEY_TASK_LIST))
            .from(DataSource.collection(context.getDataSource(COLLECTION_USERS)))
            .where(Expression.property(KEY_PARENT_LIST_ID).equalTo(Expression.string(taskListId)))
            .orderBy(Ordering.property(KEY_USERNAME));

        List<TaskListUser> users = new ArrayList<>();
        try (ResultSet rs = query.execute()) {
            List<Result> results = rs.allResults();
            System.out.println("###### GET USERS: " + results.size());
            for (Result r: results) {
                TaskListUser user = new TaskListUser();
                user.setId(r.getString(0));
                user.setName(r.getString(1));

                TaskList taskList = new TaskList();
                taskList.setId(r.getString(0));
                taskList.setOwner(r.getString(1));
                user.setTaskList(taskList);

                users.add(user);

                System.out.println("USER: found: " + user);
            }
        }

        return users;
    }


    private String id;
    private String name;
    private TaskList taskList;

    public String getId() { return id; }

    public void setId(String id) { this.id = id; }

    public String getName() { return name; }

    public void setName(String name) { this.name = name; }

    public TaskList getTaskList() { return taskList; }

    public void setTaskList(TaskList taskList) { this.taskList = taskList; }

    public String toString() { return "USER@" + id + "{" + name + ", " + taskList.getName() + "}"; }
}
