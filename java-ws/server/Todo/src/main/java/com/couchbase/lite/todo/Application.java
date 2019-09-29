package com.couchbase.lite.todo;

import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.todo.support.ResponseFilter;
import com.couchbase.lite.todo.support.SessionManager;

import org.glassfish.jersey.jackson.JacksonFeature;
import org.glassfish.jersey.media.multipart.MultiPartFeature;
import org.glassfish.jersey.server.ResourceConfig;
import org.glassfish.jersey.server.spi.Container;
import org.glassfish.jersey.server.spi.ContainerLifecycleListener;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.ws.rs.ApplicationPath;

@ApplicationPath("/")
public class Application extends ResourceConfig {
    public static final int SESSION_MAX_INACTIVE_INTERVAL_SECONDS = 3600;

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

        System.out.println("> Database Directory: " + getDatabaseDirectory());

        System.out.println("> Sync Gateway URL: " + getSyncGatewayUrl());
    }

    public static String getDatabaseDirectory() {
        return (String) getEnvironmentConfig("databaseDirectory");
    }

    public static String getSyncGatewayUrl() {
        return (String) getEnvironmentConfig("syncGatewayUrl");
    }

    private static Object getEnvironmentConfig(String name) {
        try {
            Context context = new InitialContext();
            return context.lookup("java:/comp/env/" + name);
        } catch (NamingException e) {
            e.printStackTrace();
        }
        return null;
    }

    private static class ApplicationLifecycleListener implements ContainerLifecycleListener {
        @Override
        public void onStartup(Container container) { }

        @Override
        public void onReload(Container container) { }

        @Override
        public void onShutdown(Container container) {
            SessionManager.manager().unregisterAll();
        }
    }
}
