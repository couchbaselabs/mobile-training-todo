package com.couchbase.lite.todo.model;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URI;
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
import com.couchbase.lite.todo.Logger;
import com.couchbase.lite.todo.support.ResponseException;
import com.couchbase.lite.todo.support.UserContext;
import com.couchbase.lite.todo.util.Preconditions;


public class TaskList {
    public static final String COLLECTION_LISTS = "lists";

    private static final String KEY_NAME = "name";
    private static final String KEY_OWNER = "owner";

    private static final String REQ_BODY_BEGIN = "{\"name\":\"lists.";
    private static final String REQ_BODY_END = (
        ".contributor\","
            + "\"collection_access\": {"
            + "     \"_default\": {"
            + "         \"lists\": {\"admin_channels\": []},"
            + "         \"tasks\": {\"admin_channels\": []},"
            + "         \"users\": {\"admin_channels\": []}"
            + "      }"
            + "  }"
            + "}")
        .replace(" ", "");

    public static String create(UserContext context, TaskList list) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(list.getName(), "name");

        String username = context.getUsername();
        String docId = username + "." + UUID.randomUUID();
        MutableDocument mDoc = new MutableDocument(docId);
        mDoc.setValue(KEY_NAME, list.getName());
        mDoc.setValue(KEY_OWNER, username);

        Collection collection = context.getDataSource(COLLECTION_LISTS);

        createList(collection, mDoc);

        Document doc = collection.getDocument(mDoc.getId());
        Logger.log("LIST: Created list: " + doc.toJSON());

        return docId;
    }

    public static void update(UserContext context, String id, TaskList list) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(id, "id");
        Preconditions.checkArgNotNull(list.getName(), "name");

        Collection collection = context.getDataSource(COLLECTION_LISTS);

        Document doc = collection.getDocument(id);
        if (doc == null) { throw ResponseException.notFound("Task List: " + id); }

        collection.save(doc.toMutable().setValue("name", list.getName()));

        Logger.log("LIST: Updated list: " + collection.getDocument(id).toJSON());
    }

    public static void delete(UserContext context, String id) throws CouchbaseLiteException {
        Preconditions.checkArgNotNull(id, "id");

        Collection collection = context.getDataSource(COLLECTION_LISTS);
        Document doc = collection.getDocument(id);
        if (doc != null) { collection.delete(doc); }
        Logger.log("LIST: Deleted list: " + doc.toJSON());
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

                Logger.log("LIST: found: " + taskList);
            }
        }

        return lists;
    }

    private static void createList(Collection collection, MutableDocument doc) throws CouchbaseLiteException {
        final String sgwURL = Application.getSyncGatewayUrl();
        final URI sgUri;
        try { sgUri = URI.create(sgwURL).normalize(); }
        catch (IllegalArgumentException err) {
            Logger.log("Invalid SG URI: " + sgwURL, err);
            return;
        }

        final String adminUri = "http://" + sgUri.getHost() + ":4985/todo/_role/";
        final URL sgAdminUrl;
        try { sgAdminUrl = new URL(adminUri); }
        catch (MalformedURLException e) {
            Logger.log("Bad admin URL: " + adminUri, e);
            return;
        }

        final String body = REQ_BODY_BEGIN + doc.getId() + REQ_BODY_END;
        Logger.log("Creating role: " + adminUri + "\n" + body);

        final Request request = new Request.Builder()
            .url(sgAdminUrl)
            .addHeader("Authorization", Credentials.basic("admin", "password"))
            .post(RequestBody.create(
                MediaType.parse("application/json"), body))
            .build();

        try (Response response = new OkHttpClient.Builder().build().newCall(request).execute()) {
            // 409 is CONFLICT, which means the role already exists
            if (!response.isSuccessful() && (409 != response.code())) {
                Logger.log("Create role request failed: " + response);
                return;
            }
        }
        catch (IOException e) {
            Logger.log("Create role request error", e);
            return;
        }

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
