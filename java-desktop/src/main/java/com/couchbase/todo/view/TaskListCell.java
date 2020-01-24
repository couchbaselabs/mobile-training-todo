package com.couchbase.todo.view;

import javafx.scene.control.ContextMenu;
import javafx.scene.control.ListCell;
import javafx.scene.control.MenuItem;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.todo.model.TaskList;

public class TaskListCell extends ListCell<TaskList> {

    public interface TaskListCellListener {
        void onTaskListCellEditMenuSelected(@NotNull TaskList taskList);
        void onTaskListCellDeleteMenuSelected(@NotNull TaskList taskList);
    }

    private @Nullable TaskList taskList;

    private @NotNull TaskListCellListener listener;

    public TaskListCell(@NotNull TaskListCellListener listener) {
        this.listener = listener;
    }

    @Override
    protected void updateItem(TaskList taskList, boolean empty) {
        super.updateItem(taskList, empty);

        this.taskList = taskList;

        if (empty || taskList == null) {
            setText(null);
            setContextMenu(null);
            return;
        }

        setText(taskList.getName());

        setupContextMenu();
    }

    private void setupContextMenu() {
        ContextMenu menu = getContextMenu();
        if (menu != null) return;

        MenuItem edit = new MenuItem("Edit");
        edit.setOnAction(event -> {
            this.listener.onTaskListCellEditMenuSelected(this.taskList);
        });

        MenuItem delete = new MenuItem("Delete");
        delete.setOnAction(event -> {
            this.listener.onTaskListCellDeleteMenuSelected(this.taskList);
        });

        menu = new ContextMenu(edit, delete);
        setContextMenu(menu);
    }

}
