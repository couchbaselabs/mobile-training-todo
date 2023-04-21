package com.couchbase.lite.todo.support;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import jakarta.servlet.http.HttpSession;

import com.couchbase.lite.CollectionConfiguration;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.DatabaseConfiguration;
import com.couchbase.lite.Document;
import com.couchbase.lite.Replicator;
import com.couchbase.lite.ReplicatorActivityLevel;
import com.couchbase.lite.ReplicatorConfiguration;
import com.couchbase.lite.ReplicatorStatus;
import com.couchbase.lite.SessionAuthenticator;
import com.couchbase.lite.URLEndpoint;
import com.couchbase.lite.todo.Application;
import com.couchbase.lite.todo.Logger;
import com.couchbase.lite.todo.model.User;


public class SessionManager {
    public static final String HTTP_SESSION_USER_KEY = "user";
    public static final String HTTP_SESSION_USER_CONTEXT_KEY = "userContext";
    public static final String HTTP_SESSION_SYNC_GATEWAY_SESSION_KEY = "syncGatewaySession";

    private final Map<String, UserContext> contexts = new HashMap<>();

    private final Map<String, List<HttpSession>> sessions = new HashMap<>();

    private static SessionManager instance;

    private SessionManager() { }

    public static synchronized SessionManager manager() {
        if (instance == null) {
            instance = new SessionManager();
        }
        return instance;
    }

    public synchronized boolean register(HttpSession session, User user, String syncGatewaySession) {
        String username = user.getName();

        // Check whether the user's context has been created:
        UserContext context = contexts.get(username);
        if (context == null) {
            // Get or create the user's database:
            Database database = getDatabase(username);
            if (database == null) { return false; }

            // Create and save a new user's context:
            context = new UserContext(username, database);
            contexts.put(username, context);
        }

        // Stop the current replicator:
        Replicator replicator = context.getReplicator();
        if (replicator != null) { replicator.stop(); }

        // Start a new replicator with the new sync gateway session:
        if (syncGatewaySession != null) {
            replicator = startReplication(context, syncGatewaySession);
            if (replicator == null) { return false; }
            context.setReplicator(replicator);
            session.setAttribute(HTTP_SESSION_SYNC_GATEWAY_SESSION_KEY, syncGatewaySession);
        }

        // Set session's attributes:
        session.setAttribute(HTTP_SESSION_USER_KEY, user);
        session.setAttribute(HTTP_SESSION_USER_CONTEXT_KEY, context);

        // Save the session into the user's session lists:
        List<HttpSession> userSessions = sessions.computeIfAbsent(username, k -> new ArrayList<>());
        userSessions.add(session);

        return true;
    }

    public synchronized void unregister(HttpSession session) {
        // Get username:
        User user = (User) session.getAttribute(HTTP_SESSION_USER_KEY);
        if (user == null) { return; }
        String username = user.getName();

        // Get the user's session list:
        List<HttpSession> userSessions = sessions.get(username);
        if (userSessions == null) { return; }

        // Remove the given session from the user's session list:
        if (userSessions.remove(session) && userSessions.size() == 0) {
            // When there are no user's sessions left:
            // Clean up the empty list:
            sessions.remove(username);
            // Remove the user's context:
            UserContext context = contexts.remove(username);
            // Stop the replicator:
            Replicator repl = context.getReplicator();
            if (repl != null) { repl.stop(); }
        }
    }

    public synchronized void unregisterAll() {
        for (String username: sessions.keySet()) { unregisterAll(username); }
    }

    public synchronized void unregisterAll(String username) {
        List<HttpSession> userSessions = sessions.get(username);
        if (userSessions == null) { return; }
        for (int i = userSessions.size() - 1; i >= 0; i--) { unregister(userSessions.get(i)); }
    }

    public synchronized boolean isRegistered(HttpSession session) {
        User user = (User) session.getAttribute(HTTP_SESSION_USER_KEY);
        if (user == null) { return false; }

        String username = user.getName();
        List<HttpSession> userSessions = sessions.get(username);
        return userSessions != null && userSessions.contains(session);
    }

    private Database getDatabase(String username) {
        DatabaseConfiguration config = new DatabaseConfiguration();
        config.setDirectory(Application.getDatabaseDirectory());
        try { return new Database(username, config); }
        catch (CouchbaseLiteException e) {
            Logger.log("Failed opening database: " + username, e);
        }
        return null;
    }

    private Replicator startReplication(UserContext context, String syncGatewaySession) {
        String url = Application.getSyncGatewayUrl();
        URI sgwUri;
        try { sgwUri = new URI(url); }
        catch (URISyntaxException e) {
            Logger.log("Failed parsing URL: " + url, e);
            return null;
        }
        final CollectionConfiguration collConfig = new CollectionConfiguration();
        String mode = Application.getCustomConflictResolution();
        if (!"default".equals(mode)) {
            collConfig.setConflictResolver(conflict -> {
                Document local = conflict.getLocalDocument();
                Document remote = conflict.getRemoteDocument();
                if (local == null || remote == null) { return null; }
                switch (mode) {
                    case "local":
                        return local;
                    case "remote":
                        return remote;
                    default:
                        return null;
                }
            });
        }

        ReplicatorConfiguration config
            = new ReplicatorConfiguration(new URLEndpoint(sgwUri))
            .addCollections(context.getCollections(), collConfig)
            .setContinuous(true)
            .setMaxAttempts(Application.getMaxRetries())
            .setMaxAttemptWaitTime(Application.getWaitTime());

        config.setAuthenticator(new SessionAuthenticator(syncGatewaySession));
        final Replicator replicator = new Replicator(config);
        replicator.addChangeListener(change -> {
            ReplicatorStatus status = change.getStatus();
            if (status.getActivityLevel() == ReplicatorActivityLevel.STOPPED && status.getError() != null) {
                unregisterAll(context.getUsername());
            }
        });

        replicator.start();

        return replicator;
    }
}
