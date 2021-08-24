package com.couchbase.todo.controller;

import java.net.URL;
import java.util.*;

import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.ListView;
import javafx.scene.control.TextInputDialog;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.*;
import com.couchbase.todo.model.DB;
import com.couchbase.todo.model.TaskList;
import com.couchbase.todo.model.service.DeleteDocService;
import com.couchbase.todo.model.service.SaveDocService;
import com.couchbase.todo.view.TaskListCell;


public final class TaskListsController implements Initializable, TaskListCell.TaskListCellListener {
    private static final String TYPE = "task-list";
    private static final String TABLE_TASK_LIST = "tasklist";
    private static final String TABLE_TASK = "task";
    private static final String KEY_TYPE = "type";
    private static final String KEY_NAME = "name";
    private static final String KEY_OWNER = "owner";
    private static final String KEY_COMPLETE = "complete";
    private static final String KEY_TODO = "todo";
    private static final String KEY_TASKLIST_ID = "taskList.id";

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
                SelectResult.expression(Meta.id),
                SelectResult.property(KEY_NAME),
                SelectResult.property(KEY_OWNER))
            .from(db.getDataSource())
            .where(Expression.property(KEY_TYPE).equalTo(Expression.string(TYPE)))
            .orderBy(Ordering.property(KEY_NAME));

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
            doc.setValue(KEY_TYPE, TYPE);
            doc.setValue(KEY_NAME, name);
            doc.setValue(KEY_OWNER, username);
            new SaveDocService(doc).start();
        });
    }

    private void updateName(@NotNull TaskList taskList) {
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
        ObservableList<TaskList> taskLists = FXCollections.observableArrayList();
        for (Result r: results) { taskLists.add(new TaskList(r.getString(0), r.getString(1), r.getString(2))); }
        listView.setItems(taskLists);

        DB db = DB.get();

        if (results.isEmpty()) {
            if (todoQuery != null) {
                db.removeChangeListeners(todoQuery);
                todoQuery = null;
            }
            return;
        }

        if (todoQuery != null) { return; }

        todoQuery = QueryBuilder
            .select(
                SelectResult.expression(Meta.id.from(TABLE_TASK_LIST)),
                SelectResult.expression(Function.count(Meta.id.from(TABLE_TASK))).as(KEY_TODO))
            .from(db.getDataSource().as(TABLE_TASK_LIST))
            .join(Join.innerJoin(db.getDataSource().as(TABLE_TASK))
                .on(Expression.property(KEY_TASKLIST_ID).from(TABLE_TASK).equalTo(Meta.id.from(TABLE_TASK_LIST))))
            .where(Expression.property(KEY_COMPLETE).from(TABLE_TASK).equalTo(Expression.booleanValue(false)))
            .groupBy(Meta.id.from(TABLE_TASK_LIST));

        db.addChangeListener(
            todoQuery,
            change -> {
                ResultSet rs = change.getResults();
                Platform.runLater(() -> updateToDoCount((rs == null) ? Collections.emptyList() : rs.allResults()));
            });
    }

    private void updateToDoCount(List<Result> results) {
        Map<String, Integer> toDoCounts = new HashMap<>();
        for (Result result: results) { toDoCounts.put(result.getString(0), result.getInt(1)); }

        ObservableList<TaskList> taskLists = FXCollections.observableArrayList();
        for (TaskList taskList: listView.getItems()) {
            Integer todo = toDoCounts.get(taskList.getId());
            taskLists.add(new TaskList(taskList, (todo == null) ? 0 : todo));
        }
        listView.setItems(taskLists);
    }
}
