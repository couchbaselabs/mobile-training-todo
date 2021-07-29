package com.couchbase.todo;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicReference;

import com.couchbase.todo.controller.ConfigController;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import com.couchbase.todo.controller.LoginController;
import com.couchbase.todo.controller.MainController;
import com.couchbase.todo.model.Config;
import com.couchbase.todo.model.DB;


public class TodoApp extends Application {
    public static final String DB_DIR = "db";
    public static final boolean SYNC_ENABLED = true;
    public static final String SYNC_URL = "ws://127.0.0.1:4984/todo";
    public static final CR_MODE SYNC_CR_MODE = CR_MODE.DEFAULT;
    public static final boolean LOG_ENABLED = true;
    public static final boolean LOGIN_REQUIRED = true;
    public static final String LOGIN_FXML = "/scene/Login.fxml";
    public static final String MAIN_FXML = "/scene/Main.fxml";
    public static final String CONFIG_FXML = "/scene/Config.fxml";

    public static Config config;
    public static AtomicReference<Config> aConfig = new AtomicReference<>();

    public enum CR_MODE {DEFAULT, LOCAL, REMOTE}

    @Override
    public void init() throws Exception {
        super.init();
        config = Config.builder().build();
    }

    @Override
    public void start(Stage primaryStage) {
        primaryStage.setTitle("Todo");
        goToPage(primaryStage, LOGIN_FXML);
        primaryStage.show();
    }

    @Override
    public void stop() throws Exception {
        DB.get().shutdown();
        super.stop();
    }

    public static void goToPage(Stage stage, String fxmlFile) {
        FXMLLoader loader = new FXMLLoader(TodoApp.class.getResource(fxmlFile));
        switch (fxmlFile) {
            case MAIN_FXML:
                loader.setController(new MainController(stage));
                break;
            case LOGIN_FXML:
                loader.setController(new LoginController(stage));
                break;
            case CONFIG_FXML:
                loader.setController(new ConfigController(stage));
                break;
        }
        Parent root;
        try { root = loader.load(); }
        catch (IOException e) { throw new RuntimeException("IOException when set scene to : " + fxmlFile, e); }
        Scene scene = new Scene(root);
        stage.setScene(scene);
    }

    public static Config getConfig() {
        config = aConfig.get();
        if (config != null) { return config; }
        config = new Config.Builder().build();
        aConfig.compareAndSet(null, config);
        return aConfig.get();
    }

    public static void setConfig(Config newConfig) {
        if (newConfig == null) { throw new NullPointerException("Parameter cannot be null"); }
        aConfig.compareAndSet(config, newConfig);
    }

    public static void main(String[] args) { launch(args); }
}
