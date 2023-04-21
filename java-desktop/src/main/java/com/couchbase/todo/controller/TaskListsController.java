package com.couchbase.todo.controller;

import java.net.URL;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
import com.couchbase.lite.Function;
import com.couchbase.lite.Join;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.Logger;
import com.couchbase.todo.model.DB;
import com.couchbase.todo.model.TaskList;
import com.couchbase.todo.model.service.CreateListService;
import com.couchbase.todo.model.service.DeleteDocService;
import com.couchbase.todo.model.service.SaveDocService;
import com.couchbase.todo.view.TaskListCell;


public final class TaskListsController implements Initializable, TaskListCell.TaskListCellListener {
    private static final String COL_ID = "id";
    private static final String COL_UNFINISHED = "unfinished";
    private static final String COL_NAME = "name";
    private static final String COL_OWNER = "owner";

    @FXML
    private ListView<TaskList> listView;

    @FXML
    private Button createListButton;

    private Query todoQuery;

    // set during program initialization, in MainController.initialize
    @SuppressWarnings("NotNullFieldNotInitialized")
    @NotNull
    private TaskListController taskListController;

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        registerEventHandlers();

        listView.setItems(FXCollections.observableArrayList());
        listView.setCellFactory(listView -> new TaskListCell(this));

        DB db = DB.get();

        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id).as(COL_ID),
                SelectResult.property(DB.KEY_NAME),
                SelectResult.property(DB.KEY_OWNER))
            .from(db.getDataSource(DB.COLLECTION_LISTS))
            .orderBy(Ordering.property(DB.KEY_NAME));

        db.addChangeListener(
            query,
            change -> {
                ResultSet rs = change.getResults();
                Platform.runLater(() -> updateTaskList((rs == null) ? Collections.emptyList() : rs.allResults()));
            });
    }

    private void registerEventHandlers() {
        createListButton.setOnAction(event -> createList());

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
            String docId = username + "." + UUID.randomUUID();
            MutableDocument doc = new MutableDocument(docId);
            doc.setValue(DB.KEY_NAME, name);
            doc.setValue(DB.KEY_OWNER, username);
            Logger.log("Create List: " + doc);
            new CreateListService(doc).start();
        });
    }

    private void updateName(@NotNull TaskList taskList) {
        TextInputDialog dialog = new TextInputDialog(taskList.getName());
        dialog.setTitle("New List");
        dialog.setHeaderText("Enter List Name");
        dialog.setContentText("List Name");
        Optional<String> result = dialog.showAndWait();
        result.ifPresent(name -> {
            Document doc = DB.get().getDocument(DB.COLLECTION_LISTS, taskList.getId());
            if (doc != null) {
                MutableDocument mDoc = doc.toMutable();
                mDoc.setValue(DB.KEY_NAME, name);
                new SaveDocService(DB.COLLECTION_LISTS, mDoc).start();
            }
        });
    }

    private void deleteList(TaskList taskList) {
        new DeleteDocService(DB.COLLECTION_LISTS, taskList.getId()).start();

        TaskList selTaskList = taskListController.getTaskList();
        if (selTaskList != null) {
            if (taskList.getId().equals(selTaskList.getId())) { taskListController.setTaskList(null); }
        }
    }

    @Override
    public void onTaskListCellEditMenuSelected(@NotNull TaskList taskList) {
        updateName(taskList);
    }

    @Override
    public void onTaskListCellDeleteMenuSelected(@NotNull TaskList taskList) {
        deleteList(taskList);
    }

    private void updateTaskList(List<Result> results) {
        listView.setItems(FXCollections.observableArrayList());
        ObservableList<TaskList> taskLists = listView.getItems();
        for (Result r: results) {
            TaskList list = TaskList.create(r.getString(COL_ID), r.getString(COL_NAME), r.getString(COL_OWNER));
            if (list != null) {
                taskLists.add(list);
                if (MainController.JSON_BOOLEAN.get()) { Logger.log("Update list to JSON: " + r.toJSON()); }
            }
        }

        DB db = DB.get();

        if (results.isEmpty()) {
            if (todoQuery != null) {
                db.removeChangeListeners(todoQuery);
                todoQuery = null;
            }
            return;
        }

        todoQuery = QueryBuilder
            .select(
                SelectResult.expression(Meta.id.from("lists")).as(COL_ID),
                SelectResult.expression(Function.count(Meta.id.from("tasks"))).as(COL_UNFINISHED))
            .from(db.getDataSource(DB.COLLECTION_LISTS).as("lists"))
            .join(Join.innerJoin(db.getDataSource(DB.COLLECTION_TASKS).as("tasks"))
                .on(Expression.property(DB.KEY_PARENT_LIST_ID).from("tasks").equalTo(Meta.id.from("lists"))))
            .where(Expression.property(DB.KEY_COMPLETE).from("tasks").equalTo(Expression.booleanValue(false)))
            .groupBy(Meta.id.from("lists"));

        db.addChangeListener(
            todoQuery,
            change -> {
                ResultSet rs = change.getResults();
                Platform.runLater(() -> updateToDoCount((rs == null) ? Collections.emptyList() : rs.allResults()));
            });
    }

    private void updateToDoCount(List<Result> results) {
        Map<String, Integer> toDoCounts = new HashMap<>();
        for (Result result: results) {
            toDoCounts.put(result.getString(COL_ID), result.getInt(COL_UNFINISHED));
            if (MainController.JSON_BOOLEAN.get()) {
                Logger.log("Updated count of list toJson: " + result.toJSON());
            }
        }

        ObservableList<TaskList> taskLists = FXCollections.observableArrayList();
        for (TaskList taskList: listView.getItems()) {
            Integer todo = toDoCounts.get(taskList.getId());
            taskLists.add(new TaskList(taskList, (todo == null) ? 0 : todo));
        }

        listView.setItems(taskLists);
    }
}
