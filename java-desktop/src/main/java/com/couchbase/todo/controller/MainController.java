package com.couchbase.todo.controller;

import java.net.URL;
import java.util.ResourceBundle;
import java.util.concurrent.atomic.AtomicBoolean;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.MenuItem;
import javafx.scene.control.Toggle;
import javafx.scene.control.ToggleGroup;
import javafx.stage.Stage;
import org.jetbrains.annotations.NotNull;

import com.couchbase.todo.TodoApp;
import com.couchbase.todo.model.DB;


public class MainController implements Initializable {
    @NotNull
    private final Stage stage;

    @FXML
    private TaskListsController taskListsController;

    @FXML
    private TaskListController taskListController;

    @FXML
    private MenuItem logoutMenuItem;

    @FXML
    private MenuItem configMenuItem;

    @FXML
    private ToggleGroup group;

    @FXML
    private Toggle onToggle;

    public static final AtomicBoolean JSON_BOOLEAN = new AtomicBoolean(true);

    public MainController(@NotNull Stage stage) { this.stage = stage; }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        taskListsController.setTaskListController(taskListController);

        logoutMenuItem.setOnAction(event -> {
            DB.get().logout();
            TodoApp.goToPage(this.stage, TodoApp.LOGIN_FXML);
        });
        configMenuItem.setOnAction(event -> TodoApp.goToPage(this.stage, TodoApp.CONFIG_FXML));

        //default select enable JSONResults
        group.selectToggle(onToggle);

        group.selectedToggleProperty().addListener((ign1, ign2, ign3) ->
            JSON_BOOLEAN.set(group.getSelectedToggle() == onToggle));
    }
}
