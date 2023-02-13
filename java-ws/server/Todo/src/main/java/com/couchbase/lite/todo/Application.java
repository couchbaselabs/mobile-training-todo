package com.couchbase.lite.todo;

import javax.naming.InitialContext;
import javax.naming.NamingException;

import jakarta.ws.rs.ApplicationPath;
import org.glassfish.jersey.jackson.JacksonFeature;
import org.glassfish.jersey.media.multipart.MultiPartFeature;
import org.glassfish.jersey.server.ResourceConfig;
import org.glassfish.jersey.server.spi.Container;
import org.glassfish.jersey.server.spi.ContainerLifecycleListener;

import com.couchbase.lite.ConsoleLogger;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.Database;
import com.couchbase.lite.LogDomain;
import com.couchbase.lite.LogLevel;
import com.couchbase.lite.todo.support.ResponseFilter;
import com.couchbase.lite.todo.support.SessionManager;


@ApplicationPath("/")
public class Application extends ResourceConfig {
    public static final int SESSION_MAX_INACTIVE_INTERVAL_SECONDS = 3600;

    private static class ApplicationLifecycleListener implements ContainerLifecycleListener {
        @Override
        public void onStartup(Container container) { }

        @Override
        public void onReload(Container container) { }

        @Override
        public void onShutdown(Container container) { SessionManager.manager().unregisterAll(); }
    }

    public static String getDatabaseDirectory() { return getString("databaseDirectory"); }

    public static String getSyncGatewayUrl() { return getString("syncGatewayUrl"); }

    public static boolean getLoggingEnabled() { return getBoolean("loggingEnabled"); }

    public static boolean getLoginRequired() { return getBoolean("loginRequired"); }

    public static int getMaxRetries() { return getInt("maxRetries"); }

    public static int getWaitTime() { return getInt("waitTime"); }

    public static String getCustomConflictResolution() { return getString("customConflictResolution"); }

    private static boolean getBoolean(String name) {
        Object val = getEnv(name);
        return (val instanceof Boolean) && (Boolean) val;
    }

    private static int getInt(String name) {
        Object val = getEnv(name);
        return (!(val instanceof Integer)) ? 0 : (Integer) val;
    }

    private static String getString(String name) {
        Object val = getEnv(name);
        return (!(val instanceof String)) ? "" : (String) val;
    }

    private static Object getEnv(String name) {
        try { return new InitialContext().lookup("java:/comp/env/" + name); }
        catch (NamingException e) { System.out.println("No such name: " + name); }
        return null;
    }


    public Application() {
        CouchbaseLite.init();

        packages("com.couchbase.lite.todo");

        // Application lifecycle listener:
        register(new ApplicationLifecycleListener());

        // CORS Enabled:
        register(ResponseFilter.class);

        // JSON Request / Response:
        register(JacksonFeature.class);

        // Multipart request:
        register(MultiPartFeature.class);

        if (getLoggingEnabled()) {
            ConsoleLogger logger = Database.log.getConsole();
            logger.setDomains(LogDomain.ALL_DOMAINS);
            logger.setLevel(LogLevel.DEBUG);
        }

        System.out.println("> Database Directory: " + getDatabaseDirectory());
        System.out.println("> Sync Gateway URL: " + getSyncGatewayUrl());
        System.out.println("> Verbose Logging: " + getLoggingEnabled());
        System.out.println("> Login Required: " + getLoginRequired());
        System.out.println("> Custom Conflict Resolution: " + getCustomConflictResolution());
        System.out.println("> Max retries: " + getMaxRetries());
        System.out.println("> Wait time: " + getWaitTime());
    }
}
