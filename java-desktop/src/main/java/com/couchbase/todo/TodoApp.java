package com.couchbase.todo;

import java.io.IOException;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import com.couchbase.todo.controller.LoginController;
import com.couchbase.todo.controller.MainController;
import com.couchbase.todo.model.DB;


public class TodoApp extends Application {

    public static final String DB_DIR = "db";
    public static final boolean SYNC_ENABLED = true;
    public static final String SYNC_URL = "ws://127.0.0.1:4984/todo";
    public static final boolean LOG_ENABLED = true;

    @Override
    public void start(Stage stage) throws Exception {
        stage.setTitle("Todo");
        gotoLoginScreen(stage);
        stage.show();
    }

    @Override
    public void stop() throws Exception {
        DB.get().shutdown();
        super.stop();
    }

    public static void gotoLoginScreen(Stage stage) {
        try {
            FXMLLoader loader = new FXMLLoader(TodoApp.class.getResource("/scene/Login.fxml"));
            loader.setController(new LoginController(stage));
            Parent root = loader.load();
            Scene scene = new Scene(root);
            stage.setScene(scene);
        }
        catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    public static void gotoMainScreen(Stage stage) {
        try {
            FXMLLoader loader = new FXMLLoader(TodoApp.class.getResource("/scene/main.fxml"));
            loader.setController(new MainController(stage));
            Parent root = loader.load();
            Scene scene = new Scene(root);
            stage.setScene(scene);
        }
        catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    public static void main(String[] args) {
        launch(args);
    }

}
