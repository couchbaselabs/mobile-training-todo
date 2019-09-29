package com.couchbase.lite.todo.support;

import com.couchbase.lite.*;
import com.couchbase.lite.todo.Application;
import com.couchbase.lite.todo.model.User;

import javax.servlet.http.HttpSession;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SessionManager {
    public static final String HTTP_SESSION_USER_KEY = "user";
    public static final String HTTP_SESSION_SYNC_GATEWAY_SESSION_KEY = "syncGatewaySession";
    public static final String HTTP_SESSION_USER_CONTEXT_KEY = "userContext";

    private Map<String, UserContext> contexts = new HashMap<>();

    private Map<String, List<HttpSession>> sessions = new HashMap<>();

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
        replicator = startReplication(username, context.getDatabase(), syncGatewaySession);
        context.setReplicator(replicator);

        // Set session's attributes:
        session.setAttribute(HTTP_SESSION_USER_KEY, user);
        session.setAttribute(HTTP_SESSION_SYNC_GATEWAY_SESSION_KEY, syncGatewaySession);
        session.setAttribute(HTTP_SESSION_USER_CONTEXT_KEY, context);

        // Save the session into the user's session lists:
        List<HttpSession> userSessions = sessions.get(username);
        if (userSessions == null) {
            userSessions = new ArrayList<>();
            sessions.put(username, userSessions);
        }
        userSessions.add(session);

        return true;
    }

    public synchronized void unregister(HttpSession session) {
        // Get username:
        User user = (User) session.getAttribute(HTTP_SESSION_USER_KEY);
        if (user == null) { return; }
        String username = user.getName();

        // Get the user's session list:
        List userSessions = sessions.get(username);
        if (userSessions == null) { return; }

        // Remove the given session from the user's session list:
        if (userSessions.remove(session) && userSessions.size() == 0) {
            // When there are no user's sessions left:
            // Clean up the empty list:
            sessions.remove(username);
            // Remove the user's context:
            UserContext context = contexts.remove(username);
            // Stop the replicator:
            context.getReplicator().stop();
        }
    }

    public synchronized void unregisterAll() {
        for (String username : sessions.keySet()) {
            unregisterAll(username);
        }
    }

    public synchronized void unregisterAll(String username) {
        List<HttpSession> userSessions = sessions.get(username);
        if (userSessions == null) { return; }
        for (int i = userSessions.size() - 1; i >= 0; i--) {
            unregister(userSessions.get(i));
        }
    }

    public synchronized boolean isRegistered(HttpSession session) {
        User user = (User) session.getAttribute(HTTP_SESSION_USER_KEY);
        if (user == null) { return false; }

        String username = user.getName();
        List userSessions = sessions.get(username);
        return userSessions != null && userSessions.contains(session);
    }

    private Database getDatabase(String username) {
        DatabaseConfiguration config = new DatabaseConfiguration();
        config.setDirectory(Application.getDatabaseDirectory());
        try {
            return new Database(username, config);
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }
        return null;
    }

    private Replicator startReplication(String username, Database database, String syncGatewaySession) {
        URLEndpoint endpoint = null;
        try { endpoint = new URLEndpoint(new URI(Application.getSyncGatewayUrl())); } catch (URISyntaxException e) { }

        ReplicatorConfiguration config = new ReplicatorConfiguration(database, endpoint);
        config.setContinuous(true);
        config.setAuthenticator(new SessionAuthenticator(syncGatewaySession));
        final Replicator replicator = new Replicator(config);
        replicator.addChangeListener(change -> {
            Replicator.Status status = change.getStatus();
            if (status.getActivityLevel() == Replicator.ActivityLevel.STOPPED && status.getError() != null) {
                unregisterAll(username);
            }
        });
        replicator.start();
        return replicator;
    }
}
