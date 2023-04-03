package com.couchbase.lite.todo.model;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import okhttp3.Credentials;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.DataSource;
import com.couchbase.lite.Document;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.lite.todo.Application;
import com.couchbase.lite.todo.support.ResponseException;
import com.couchbase.lite.todo.support.UserContext;
import com.couchbase.lite.todo.util.Preconditions;


public class TaskList {
    public static final String COLLECTION_LISTS = "lists";

    private static final String KEY_NAME = "name";
    private static final String KEY_OWNER = "owner";

    public static String create(UserContext context, TaskList list) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(list.getName(), "name");

        String username = context.getUsername();
        String docId = username + "." + UUID.randomUUID();
        MutableDocument doc = new MutableDocument(docId);
        doc.setValue(KEY_NAME, list.getName());
        doc.setValue(KEY_OWNER, username);

        Collection collection = context.getDataSource(COLLECTION_LISTS);

        createList(collection, doc);

        System.out.println("LIST: Created list: " + collection.getDocument(docId).toJSON());

        return doc.getId();
    }

    public static void update(UserContext context, String id, TaskList list) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(id, "id");
        Preconditions.checkArgNotNull(list.getName(), "name");

        Collection collection = context.getDataSource(COLLECTION_LISTS);

        Document doc = collection.getDocument(id);
        if (doc == null) { throw ResponseException.notFound("Task List: " + id); }

        collection.save(doc.toMutable().setValue("name", list.getName()));

        System.out.println("LIST: Updated list: " + collection.getDocument(id).toJSON());
    }

    public static void delete(UserContext context, String id) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(id, "id");

        Collection collection = context.getDataSource(COLLECTION_LISTS);
        Document doc = collection.getDocument(id);
        if (doc != null) { collection.delete(doc); }
        System.out.println("LIST: Deleted list: " + doc.toJSON());
    }

    public static List<TaskList> getTaskLists(UserContext context) throws CouchbaseLiteException {
        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property(KEY_NAME),
                SelectResult.property(KEY_OWNER))
            .from(DataSource.collection(context.getDataSource(COLLECTION_LISTS)))
            .orderBy(Ordering.property(KEY_NAME));

        List<TaskList> lists = new ArrayList<>();
        try (ResultSet rs = query.execute()) {
            for (Result r: rs) {
                TaskList taskList = new TaskList();
                taskList.setId(r.getString(0));
                taskList.setName(r.getString(1));
                taskList.setOwner(r.getString(2));
                lists.add(taskList);

                System.out.println("LIST: found: " + taskList);
            }
        }

        return lists;
    }

    private static void createList(Collection collection, MutableDocument doc) throws CouchbaseLiteException {
        final URL sgUri;
        try { sgUri = new URL(Application.getSyncGatewayUrl()); }
        catch (MalformedURLException e) { return; }

        final String adminUri = "http://" + sgUri.getHost() + ":4985/todo/_role/";
        final URL sgAdminUrl;
        try { sgAdminUrl = new URL(adminUri); }
        catch (MalformedURLException e) { return; }

        final String reqBody = "{"
            + "\"name\": \"lists." + doc.getId() + ".contributor\","
            + "\"collection_access\": {"
            + "     \"_default\": {"
            + "         \"lists\": {\"admin_channels\": []},"
            + "         \"tasks\": {\"admin_channels\": []},"
            + "         \"users\": {\"admin_channels\": []}"
            + "      }"
            + "  }";

        final Request request = new Request.Builder()
            .url(sgAdminUrl)
            .addHeader("Authorization", Credentials.basic("admin", "password"))
            .post(RequestBody.create(MediaType.parse("application/json"), reqBody))
            .build();


        try (Response response = new OkHttpClient.Builder().build().newCall(request).execute()) {
            if (!response.isSuccessful()) { return; }
        }
        catch (IOException e) { return; }

        collection.save(doc);
    }


    private String id;
    private String name;
    private String owner;

    public String getId() { return id; }

    public void setId(String id) { this.id = id; }

    public String getName() { return name; }

    public void setName(String name) { this.name = name; }

    public void setOwner(String owner) { this.owner = owner; }

    public String getOwner() { return owner; }

    public String toString() { return "LIST@" + id + "{" + name + ", " + owner + "}"; }
}
