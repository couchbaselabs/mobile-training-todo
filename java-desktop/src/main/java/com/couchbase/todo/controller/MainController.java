package com.couchbase.todo.controller;

import java.io.IOException;
import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.MenuItem;
import javafx.stage.Stage;
import org.jetbrains.annotations.NotNull;

import com.couchbase.todo.TodoApp;
import com.couchbase.todo.model.DB;


public class MainController implements Initializable {

    @FXML
    private TaskListsController taskListsController;

    @FXML
    private TaskListController taskListController;

    @FXML
    private MenuItem logoutMenuItem;

    @FXML
    private MenuItem configMenuItem;

    @NotNull
    private Stage stage;

    public MainController(@NotNull Stage stage) {
        this.stage = stage;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        taskListsController.setTaskListController(taskListController);

        logoutMenuItem.setOnAction(event -> {
            DB.get().logout();
            TodoApp.setScene(this.stage, TodoApp.LOGIN_FXML);
        });
        configMenuItem.setOnAction(event -> {
            TodoApp.setScene(this.stage, TodoApp.CONFIG_FXML);
        });
    }
}
