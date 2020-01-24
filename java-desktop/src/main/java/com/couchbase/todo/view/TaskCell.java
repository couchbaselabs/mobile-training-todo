package com.couchbase.todo.view;

import java.io.IOException;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ContextMenu;
import javafx.scene.control.Label;
import javafx.scene.control.ListCell;
import javafx.scene.control.MenuItem;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.lite.Blob;
import com.couchbase.todo.model.Task;

public class TaskCell extends ListCell<Task> {

    public interface TaskCellListener {
        void onTaskCellEditNameMenuSelected(@NotNull Task task);
        void onTaskCellDeleteMenuSelected(@NotNull Task task);
        void onTaskCellEditImageMenuSelected(@NotNull Task task);
        void onTaskCellDeleteImageMenuSelected(@NotNull Task task);
        void onTaskCellCompleteChanged(@NotNull Task task, boolean newComplete);
    }

    @FXML private AnchorPane pane;

    @FXML private ImageView imageView;

    @FXML private Label nameLabel;

    @FXML private CheckBox completeCheckbox;

    @FXML private Button moreButton;

    private FXMLLoader loader;

    private Task task;

    private TaskCellListener listener;

    @Override
    protected void updateItem(Task task, boolean empty) {
        super.updateItem(task, empty);

        setTask(task);

        if (empty || task == null) {
            setGraphic(null);
            setContextMenu(null);
            return;
        }

        if (loader == null) {
            loader = new FXMLLoader(getClass().getResource("/scene/TaskCell.fxml"));
            loader.setController(this);
            try {  loader.load(); } catch (IOException e) { e.printStackTrace(); }
            registerEventHandlers();
        }

        setupContextMenu();

        nameLabel.setText(task.getName());
        completeCheckbox.setSelected(task.isComplete());
        Blob blob = task.getImage();
        if (blob != null) {
            imageView.setImage(new Image(blob.getContentStream()));
        } else {
            imageView.setImage(new Image(getClass().getResourceAsStream("/image/placeholder.png")));
        }
        setGraphic(pane);
    }

    private void setTask(@Nullable Task task) {
        this.task = task;
    }

    private @Nullable Task getTask() {
        return this.task;
    }

    private void setupContextMenu() {
        ContextMenu menu = getContextMenu();
        if (menu != null) return;

        MenuItem editName = new MenuItem("Edit Name");
        editName.setOnAction(event -> {
            TaskCellListener listener = getListener();
            if (listener != null) {
                listener.onTaskCellEditNameMenuSelected(getTask());
            }
        });

        MenuItem editImage = new MenuItem("Edit Image");
        editImage.setOnAction(event -> {
            TaskCellListener listener = getListener();
            if (listener != null) {
                listener.onTaskCellEditImageMenuSelected(getTask());
            }
        });

        MenuItem deleteImage = new MenuItem("Delete Image");
        deleteImage.setOnAction(event -> {
            TaskCellListener listener = getListener();
            if (listener != null) {
                listener.onTaskCellDeleteImageMenuSelected(getTask());
            }
        });

        MenuItem deleteTask = new MenuItem("Delete Task");
        deleteTask.setOnAction(event -> {
            TaskCellListener listener = getListener();
            if (listener != null) {
                listener.onTaskCellDeleteMenuSelected(getTask());
            }
        });

        menu = new ContextMenu(editName, editImage, deleteImage, deleteTask);
        setContextMenu(menu);
    }

    private void registerEventHandlers() {
        completeCheckbox.selectedProperty().addListener((observable, oldValue, newValue) -> {
            TaskCellListener listener = getListener();
            if (listener != null) {
                listener.onTaskCellCompleteChanged(getTask(), newValue);
            }
        });
    }

    public TaskCellListener getListener() {
        return listener;
    }

    public void setListener(TaskCellListener listener) {
        this.listener = listener;
    }

}
