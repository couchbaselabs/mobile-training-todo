package com.couchbase.todo.view;

import java.io.IOException;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.control.ContextMenu;
import javafx.scene.control.Label;
import javafx.scene.control.ListCell;
import javafx.scene.control.MenuItem;
import javafx.scene.layout.AnchorPane;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.todo.TodoApp;
import com.couchbase.todo.model.TaskList;


public class TaskListCell extends ListCell<TaskList> {
    public interface TaskListCellListener {
        void onTaskListCellEditMenuSelected(@NotNull TaskList taskList);

        void onTaskListCellDeleteMenuSelected(@NotNull TaskList taskList);
    }


    @FXML
    private AnchorPane pane;

    @FXML
    private Label nameLabel;

    @FXML
    private Label todoLabel;

    private FXMLLoader loader;

    @Nullable
    private TaskList taskList;

    @NotNull
    private final TaskListCellListener listener;

    public TaskListCell(@NotNull TaskListCellListener listener) { this.listener = listener; }

    @Override
    protected void updateItem(TaskList taskList, boolean empty) {
        super.updateItem(taskList, empty);

        setTaskList(taskList);

        if (empty || taskList == null) {
            if (nameLabel != null) { nameLabel.setText(""); }
            if (todoLabel != null) { todoLabel.setText(""); }
            setContextMenu(null);
            return;
        }

        if (loader == null) {
            loader = new FXMLLoader(TodoApp.class.getResource("/scene/TasksCell.fxml"));
            loader.setController(this);
            try { loader.load(); }
            catch (IOException e) { e.printStackTrace(); }
        }

        setupContextMenu();

        nameLabel.setText(taskList.getName());
        todoLabel.setText(String.valueOf(taskList.getTodo()));

        setGraphic(pane);
    }

    private void setTaskList(@Nullable TaskList taskList) { this.taskList = taskList; }

    private void setupContextMenu() {
        ContextMenu menu = getContextMenu();
        if (menu != null) { return; }

        MenuItem edit = new MenuItem("Edit");
        edit.setOnAction(event -> {
            if (taskList != null) { listener.onTaskListCellEditMenuSelected(taskList); }
        });

        MenuItem delete = new MenuItem("Delete");
        delete.setOnAction(event -> {
            if (taskList != null) { listener.onTaskListCellDeleteMenuSelected(taskList); }
        });

        menu = new ContextMenu(edit, delete);
        setContextMenu(menu);
    }
}
