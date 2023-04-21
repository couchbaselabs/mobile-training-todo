package com.couchbase.todo.view;

import java.io.IOException;
import java.util.Objects;

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
import com.couchbase.todo.Logger;
import com.couchbase.todo.TodoApp;
import com.couchbase.todo.model.Task;


public class TaskCell extends ListCell<Task> {

    public interface TaskCellListener {
        void onTaskCellEditNameMenuSelected(@NotNull Task task);

        void onTaskCellDeleteMenuSelected(@NotNull Task task);

        void onTaskCellEditImageMenuSelected(@NotNull Task task);

        void onTaskCellDeleteImageMenuSelected(@NotNull Task task);

        void onTaskCellCompleteChanged(@NotNull Task task, boolean newComplete);
    }

    @FXML
    private AnchorPane pane;

    @FXML
    private ImageView imageView;

    @FXML
    private Label nameLabel;

    @FXML
    private CheckBox completeCheckbox;

    @FXML
    private Button moreButton;

    private FXMLLoader loader;

    private Task task;

    private TaskCellListener listener;

    @Override
    protected void updateItem(Task task, boolean empty) {
        super.updateItem(task, empty);

        setTask(task);

        if (loader == null) {
            FXMLLoader sceneLoader = new FXMLLoader(TodoApp.class.getResource(TodoApp.TASK_FXML));
            sceneLoader.setController(this);
            try { sceneLoader.load(); }
            catch (IOException e) {
                Logger.log("Failed loading Task Cell scene", e);
                return;
            }
            loader = sceneLoader;
            registerEventHandlers();
        }

        if (empty || task == null) {
            setGraphic(null);
            setContextMenu(null);
            return;
        }

        setupContextMenu();

        nameLabel.setText(task.getName());
        completeCheckbox.setSelected(task.isComplete());
        Blob blob = task.getImage();
        if (blob != null) {
            imageView.setImage(new Image(Objects.requireNonNull(blob.getContentStream())));
        }
        else {
            imageView.setImage(new Image(Objects
                .requireNonNull(getClass().getResourceAsStream("/image/placeholder.png"))));
        }
        setGraphic(pane);
    }

    private void setTask(@Nullable Task task) { this.task = task; }

    private @Nullable Task getTask() { return this.task; }

    private void setupContextMenu() {
        ContextMenu menu = getContextMenu();
        if (menu != null) { return; }

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

    public TaskCellListener getListener() { return listener; }

    public void setListener(TaskCellListener listener) { this.listener = listener; }
}
