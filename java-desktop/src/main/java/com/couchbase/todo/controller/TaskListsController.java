package com.couchbase.todo.controller;

import java.net.URL;
import java.util.Optional;
import java.util.ResourceBundle;
import java.util.UUID;

import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.ListView;
import javafx.scene.control.TextInputDialog;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.Document;
import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.model.DB;
import com.couchbase.todo.model.service.DeleteDocService;
import com.couchbase.todo.model.service.SaveDocService;
import com.couchbase.todo.model.TaskList;
import com.couchbase.todo.view.TaskListCell;

public final class TaskListsController implements Initializable, TaskListCell.TaskListCellListener {

    private static final String TYPE = "task-list";
    private static final String KEY_TYPE = "type";
    private static final String KEY_NAME = "name";
    private static final String KEY_OWNER = "owner";

    @FXML private ListView<TaskList> listView;

    @FXML private Button createListButton;

    private @NotNull TaskListController taskListController;

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        registerEventHandlers();

        listView.setItems(FXCollections.observableArrayList());
        listView.setCellFactory(listView -> {
            TaskListCell cell = new TaskListCell(this);
            return cell;
        });

        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property(KEY_NAME),
                SelectResult.property(KEY_OWNER))
            .from(DB.get().getDataSource())
            .where(Expression.property(KEY_TYPE).equalTo(Expression.string(TYPE)))
            .orderBy(Ordering.property(KEY_NAME));

        DB.get().addChangeListener(query, change -> {
            ObservableList<TaskList> taskLists = FXCollections.observableArrayList();
            for (Result r : change.getResults()) {
                TaskList list = new TaskList(
                    r.getString(0),
                    r.getString(1),
                    r.getString(2));
                taskLists.add(list);
            }

            Platform.runLater(() -> {
                listView.setItems(taskLists);
            });
        });
    }

    private void registerEventHandlers() {
        createListButton.setOnAction(event -> {
            createList();
        });

        listView.getSelectionModel().selectedItemProperty().addListener((observable, oldValue, newValue) -> {
            if (newValue != null) { selectList(newValue); }
        });
    }

    public void setTaskListController(@NotNull TaskListController taskListController) {
        this.taskListController = taskListController;
    }

    private void selectList(TaskList taskList) {
        this.taskListController.setTaskList(taskList);
    }

    private void createList() {
        TextInputDialog dialog = new TextInputDialog();
        dialog.setTitle("New List");
        dialog.setHeaderText("Enter List Name");
        dialog.setContentText("List Name");
        Optional<String> result = dialog.showAndWait();

        result.ifPresent(name -> {
            String username = DB.get().getLoggedInUsername();
            String docId =  username + "." + UUID.randomUUID();
            MutableDocument doc = new MutableDocument(docId);
            doc.setValue(KEY_TYPE, TYPE);
            doc.setValue(KEY_NAME, name);
            doc.setValue(KEY_OWNER, username);
            new SaveDocService(doc).start();
        });
    }

    private void updateName(TaskList taskList) {
        TextInputDialog dialog = new TextInputDialog(taskList.getName());
        dialog.setTitle("New List");
        dialog.setHeaderText("Enter List Name");
        dialog.setContentText("List Name");
        Optional<String> result = dialog.showAndWait();
        result.ifPresent(name -> {
            Document doc = DB.get().getDocument(taskList.getId());
            if (doc != null) {
                MutableDocument mDoc = doc.toMutable();
                mDoc.setValue(KEY_NAME, name);
                new SaveDocService(mDoc).start();
            }
        });
    }

    private void deleteList(TaskList taskList) {
        new DeleteDocService(taskList.getId()).start();

        TaskList selTaskList = taskListController.getTaskList();
        if (selTaskList != null) { if (taskList.equals(selTaskList.getId())) {
            taskListController.setTaskList(null);}
        }
    }

    // TaskListCellListener

    @Override
    public void onTaskListCellEditMenuSelected(@NotNull TaskList taskList) {
        updateName(taskList);
    }

    @Override
    public void onTaskListCellDeleteMenuSelected(@NotNull TaskList taskList) {
        deleteList(taskList);
    }

}
