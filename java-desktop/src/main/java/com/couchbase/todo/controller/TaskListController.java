package com.couchbase.todo.controller;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.URL;
import java.net.URLConnection;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.ResourceBundle;
import java.util.concurrent.atomic.AtomicBoolean;

import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import javafx.scene.control.TextInputDialog;
import javafx.scene.layout.AnchorPane;
import javafx.stage.FileChooser;
import javafx.stage.Modality;
import javafx.stage.Stage;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.TodoApp;
import com.couchbase.todo.model.DB;
import com.couchbase.todo.model.Task;
import com.couchbase.todo.model.TaskList;
import com.couchbase.todo.model.service.DeleteDocService;
import com.couchbase.todo.model.service.SaveDocService;
import com.couchbase.todo.view.TaskCell;
import com.couchbase.todo.view.TaskCellSelectionModel;


public class TaskListController implements Initializable, TaskCell.TaskCellListener {
    @FXML
    private AnchorPane pane;

    @FXML
    private Label listNameLabel;

    @FXML
    private Button shareButton;

    @FXML
    private TextField taskTextField;

    @FXML
    private Button createTaskButton;

    @FXML
    private ListView<Task> listView;

    private final AtomicBoolean initialized = new AtomicBoolean();

    private TaskList taskList;

    private Query query;

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        registerEventHandlers();

        listView.setItems(FXCollections.observableArrayList());
        listView.setCellFactory(listView -> {
            TaskCell cell = new TaskCell();
            cell.setListener(this);
            return cell;
        });
        listView.setSelectionModel(new TaskCellSelectionModel());
        initialized.set(true);

        updateTaskList();
    }

    private void registerEventHandlers() {
        createTaskButton.setOnAction(event -> {
            String name = taskTextField.getText();
            if (name.trim().length() > 0) { createTask(name); }
            taskTextField.setText("");
        });

        shareButton.setOnAction(event -> {
            try {
                FXMLLoader loader = new FXMLLoader(TodoApp.class.getResource("/scene/Share.fxml"));
                ShareController controller = new ShareController(this.taskList);
                loader.setController(controller);
                Parent root = loader.load();
                Scene scene = new Scene(root);
                Stage stage = new Stage();
                stage.initModality(Modality.APPLICATION_MODAL);
                stage.setScene(scene);
                stage.setOnCloseRequest(event1 -> controller.close());
                stage.showAndWait();
            }
            catch (IOException e) { e.printStackTrace(); }
        });
    }

    @Nullable
    public TaskList getTaskList() { return taskList; }

    public void setTaskList(@Nullable TaskList taskList) {
        this.taskList = taskList;
        updateTaskList();
    }

    private void updateTaskList() {
        if (!initialized.get()) { return; }

        if (query != null) {
            DB.get().removeChangeListeners(query);
            query = null;
        }

        if (taskList != null) {
            query = QueryBuilder
                .select(
                    SelectResult.expression(Meta.id),
                    SelectResult.property(DB.KEY_TASK),
                    SelectResult.property(DB.KEY_COMPLETE),
                    SelectResult.property(DB.KEY_IMAGE),
                    SelectResult.property(DB.KEY_OWNER),
                    SelectResult.property(DB.KEY_CREATED_AT),
                    SelectResult.property(DB.KEY_TASK_LIST))
                .from(DB.get().getDataSource(DB.COLLECTION_TASKS))
                .where(Expression.property(DB.KEY_PARENT_LIST_ID).equalTo(Expression.string(taskList.getId())))
                .orderBy(Ordering.property(DB.KEY_CREATED_AT), Ordering.property(DB.KEY_TASK));

            DB.get().addChangeListener(
                query,
                change -> {
                    ResultSet rs = change.getResults();
                    Platform.runLater(() -> updateTasksList((rs == null) ? Collections.emptyList() : rs.allResults()));
                });

            listNameLabel.setText(taskList.getName());
            listNameLabel.setVisible(true);
            shareButton.setVisible(true);
            taskTextField.setDisable(false);
            createTaskButton.setDisable(false);
        }
        else {
            listView.getItems().clear();
            listNameLabel.setText("");
            listNameLabel.setVisible(false);
            shareButton.setVisible(false);
            taskTextField.setDisable(true);
            createTaskButton.setDisable(true);
        }
    }

    private void updateTasksList(List<Result> results) {
        ObservableList<Task> tasks = FXCollections.observableArrayList();
        for (Result r: results) {
            tasks.add(new Task(
                Objects.requireNonNull(r.getString(0)),
                Objects.requireNonNull(r.getString(1)),
                r.getBoolean(2),
                r.getBlob(3)));

            if (MainController.jsonBoolean.get()) {
                System.out.println("Update Task List to JSON: " + r.toJSON());
            }
        }
        listView.setItems(tasks);
    }

    private void createTask(@NotNull String title) {
        MutableDocument doc = new MutableDocument();
        doc.setValue(DB.KEY_CREATED_AT, new Date());
        doc.setValue(DB.KEY_TASK, title);
        doc.setValue(DB.KEY_COMPLETE, false);

        MutableDictionary taskListInfo = new MutableDictionary();
        taskListInfo.setValue(DB.KEY_TASK_LIST_ID, taskList.getId());
        taskListInfo.setValue(DB.KEY_TASK_LIST_OWNER, taskList.getOwner());
        doc.setValue(DB.KEY_TASK_LIST, taskListInfo);
       new SaveDocService(DB.COLLECTION_TASKS, doc).start();
    }

    private void updateTaskName(@NotNull String id, @NotNull String name) {
        Document doc = DB.get().getDocument(DB.COLLECTION_TASKS, id);
        if (doc == null) { return; }

        MutableDocument mDoc = doc.toMutable();
        mDoc.setValue(DB.KEY_TASK, name);
        new SaveDocService(DB.COLLECTION_TASKS, mDoc).start();
    }

    private void updateTaskComplete(@NotNull String id, boolean completion) {
        Document doc = DB.get().getDocument(DB.COLLECTION_TASKS, id);
        if (doc == null) { return; }
        if (MainController.jsonBoolean.get()) {
            System.out.println("Task doc after update complete check box: " + doc.toJSON());
        }
        MutableDocument mDoc = doc.toMutable();
        mDoc.setValue(DB.KEY_COMPLETE, completion);
        new SaveDocService(DB.COLLECTION_TASKS, mDoc).start();
    }

    private void updateTaskImage(@NotNull String id, @Nullable File image) {
        Document doc = DB.get().getDocument(DB.COLLECTION_TASKS, id);
        if (doc == null) { return; }

        MutableDocument mDoc = doc.toMutable();
        Blob blob = null;
        if (image != null) {
            try { blob = new Blob(getContentType(image), new FileInputStream(image)); }
            catch (FileNotFoundException e) {
                // TODO: Report Error
                e.printStackTrace();
            }
        }
        mDoc.setValue(DB.KEY_IMAGE, blob);
        new SaveDocService(DB.COLLECTION_TASKS, mDoc).start();
    }

    private void deleteTask(String id) { new DeleteDocService(DB.COLLECTION_TASKS, id).start(); }

    private String getContentType(File file) {
        return URLConnection.guessContentTypeFromName(file.getName());
    }

    // TaskCellListener

    @Override
    public void onTaskCellEditNameMenuSelected(@NotNull Task task) {
        TextInputDialog dialog = new TextInputDialog(task.getName());
        dialog.setTitle("Edit Task Name");
        dialog.setHeaderText("Enter Task Name");
        dialog.setContentText("Task Name");
        Optional<String> result = dialog.showAndWait();
        result.ifPresent(name -> updateTaskName(task.getId(), name));
    }

    @Override
    public void onTaskCellDeleteMenuSelected(@NotNull Task task) {
        deleteTask(task.getId());
    }

    @Override
    public void onTaskCellEditImageMenuSelected(@NotNull Task task) {
        FileChooser chooser = new FileChooser();
        chooser.setTitle("Open File");
        chooser.getExtensionFilters().add(
            new FileChooser.ExtensionFilter("Image Files", "*.png", "*.jpg"));
        File file = chooser.showOpenDialog(pane.getScene().getWindow());
        if (file != null) {
            updateTaskImage(task.getId(), file);
        }
    }

    @Override
    public void onTaskCellDeleteImageMenuSelected(@NotNull Task task) {
        updateTaskImage(task.getId(), null);
    }

    @Override
    public void onTaskCellCompleteChanged(@NotNull Task task, boolean newComplete) {
        updateTaskComplete(task.getId(), newComplete);
    }
}
