package com.couchbase.lite.todo.model;

import com.couchbase.lite.*;
import com.couchbase.lite.todo.support.ResponseException;
import com.couchbase.lite.todo.support.UserContext;
import com.couchbase.lite.todo.util.Preconditions;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class TaskList {
    private static final String TYPE = "task-list";
    private static final String KEY_TYPE = "type";
    private static final String KEY_NAME = "name";
    private static final String KEY_OWNER = "owner";

    private String id;

    private String name;

    private String owner;

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

    public void setOwner(String owner) {
        this.owner = owner;
    }

    public String getOwner() {
        return owner;
    }

    public static String create(UserContext context, TaskList list) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(list.getName(), "name");

        Database db = context.getDatabase();
        String username = context.getUsername();

        String docId = username + "." + UUID.randomUUID();
        MutableDocument doc = new MutableDocument(docId);
        doc.setValue(KEY_TYPE, TaskList.TYPE);
        doc.setValue(KEY_NAME, list.getName());
        doc.setValue(KEY_OWNER, username);
        db.save(doc);
        return doc.getId();
    }

    public static void update(UserContext context, String id, TaskList list) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(id, "id");
        Preconditions.checkArgNotNull(list.getName(), "name");

        Database db = context.getDatabase();

        Document doc = db.getDocument(id);
        if (doc == null) { throw ResponseException.NOT_FOUND("Task List: " + id); }

        db.save(doc.toMutable().setValue("name", list.getName()));
    }

    public static void delete(UserContext context, String id) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(id, "id");

        Database db = context.getDatabase();
        Document doc = db.getDocument(id);
        if (doc != null) { db.delete(doc); }
    }

    public static List<TaskList> getTaskLists(UserContext context) throws CouchbaseLiteException {
        Database database = context.getDatabase();
        Query query = QueryBuilder
                .select(SelectResult.expression(Meta.id),
                        SelectResult.property(KEY_NAME),
                        SelectResult.property(KEY_OWNER))
                .from(DataSource.database(database))
                .where(Expression.property(KEY_TYPE).equalTo(Expression.string(TaskList.TYPE)))
                .orderBy(Ordering.property(KEY_NAME));

        List<TaskList> lists = new ArrayList<>();
        ResultSet rs = query.execute();
        for (Result r : rs) {
            TaskList taskList = new TaskList();
            taskList.setId(r.getString(0));
            taskList.setName(r.getString(1));
            taskList.setOwner(r.getString(2));
            lists.add(taskList);
        }
        return lists;
    }
}
