package com.couchbase.todo;

import java.io.IOException;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import com.couchbase.todo.controller.ConfigController;
import com.couchbase.todo.controller.LoginController;
import com.couchbase.todo.controller.MainController;
import com.couchbase.todo.model.DB;


public class TodoApp extends Application {
    public enum CR_MODE {DEFAULT, LOCAL, REMOTE}

    public static final boolean SYNC_ENABLED = true;
    public static final boolean LOG_ENABLED = true;
    public static final boolean LOGIN_REQUIRED = true;

    public static final CR_MODE SYNC_CR_MODE = CR_MODE.DEFAULT;

    public static final String DB_DIR = "db";
    public static final String SYNC_URL = "ws://ec2-3-135-230-240.us-east-2.compute.amazonaws.com:4984/todo";
    public static final String LOGIN_FXML = "/scene/Login.fxml";
    public static final String MAIN_FXML = "/scene/Main.fxml";
    public static final String CONFIG_FXML = "/scene/Config.fxml";
    public static final String SHARE_FXML = "/scene/Share.fxml";
    public static final String TASKS_FXML = "/scene/TasksCell.fxml";
    public static final String TASK_FXML = "/scene/TaskCell.fxml";

    public static volatile TodoApp todoApp;

    public static TodoApp getTodoApp() { return todoApp; }

    public static void main(String[] args) { launch(args); }


    private Config config = Config.builder().build();

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

        stage.setScene(new Scene(root));
    }

    @Override
    public void start(Stage primaryStage) {
        todoApp = this;
        primaryStage.setTitle("Todo");
        goToPage(primaryStage, LOGIN_FXML);
        primaryStage.show();
    }

    @Override
    public void stop() throws Exception {
        DB.get().shutdown();
        super.stop();
        todoApp = null;
    }

    public Config getConfig() { return config; }

    public void setConfig(Config newConfig) { config = newConfig; }
}
