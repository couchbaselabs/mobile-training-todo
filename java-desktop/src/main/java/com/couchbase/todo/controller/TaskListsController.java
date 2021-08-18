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
import com.couchbase.todo.model.service.DeleteDocService;
import com.couchbase.todo.model.service.SaveDocService;
import com.couchbase.todo.model.TaskList;
import com.couchbase.todo.view.TaskListCell;


public final class TaskListsController implements Initializable, TaskListCell.TaskListCellListener {

    private static final String TYPE = "task-list";
    private static final String KEY_TYPE = "type";
    private static final String KEY_NAME = "name";
    private static final String KEY_OWNER = "owner";
    private static final String KEY_NUM_UNDONE = "num-undone";

    private final Map<String, Integer> incompleteTaskCounts = new HashMap<>();
    private final Query incompleteTasksCountQuery = getIncompleteTasksCountQuery();

    @FXML
    private ListView<TaskList> listView;

    @FXML
    private Button createListButton;

    private @NotNull TaskListController taskListController;

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        registerEventHandlers();

        listView.setItems(FXCollections.observableArrayList());
        listView.setCellFactory(listView -> new TaskListCell(this));

        Query query = QueryBuilder
            .select(
                SelectResult.expression(Meta.id),
                SelectResult.property(KEY_NAME),
                SelectResult.property(KEY_OWNER),
                SelectResult.property(KEY_NUM_UNDONE))
            .from(DB.get().getDataSource())
            .where(Expression.property(KEY_TYPE).equalTo(Expression.string(TYPE)))
            .orderBy(Ordering.property(KEY_NAME));

        DB.get().addChangeListener(query, change -> {
            ObservableList<TaskList> taskLists = FXCollections.observableArrayList();
            assert change.getResults() != null;
            for (Result r: change.getResults()) {
                TaskList list = TaskList.builder()
                    .id(r.getString(0))
                    .name(r.getString(1))
                    .owner(r.getString(2))
                    .numIncomplete(r.getInt(3))
                    .build();
                taskLists.add(list);
            }

            Platform.runLater(() -> listView.setItems(taskLists));
        });

        DB.get().addChangeListener(incompleteTasksCountQuery, this::onIncompleteTasksChanged);
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
            doc.setValue(KEY_NUM_UNDONE,0); // ??? 0 is hardcoded as the default value for num_undone
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
        if (selTaskList != null) {
            if (taskList.equals(selTaskList.getId())) {
                taskListController.setTaskList(null);
            }
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

    public void onIncompleteTasksChanged(@NotNull QueryChange change) {
        /*
        TODO
         */
        for (Result r: change.getResults()) {
            incompleteTaskCounts.put(r.getString(0), r.getInt(1));
        }
    }

    private Query getIncompleteTasksCountQuery() {
        return DB.get().createQuery(
            SelectResult.expression(Expression.property(TaskListController.KEY_TASK_LIST_ID)),
            SelectResult.expression(Function.count(Expression.all())))
            .where(Expression.property(KEY_TYPE).equalTo(Expression.string(TaskListController.KEY_TASK))
                .and(Expression.property(TaskListController.KEY_COMPLETE).equalTo(Expression.booleanValue(false))))
            .groupBy(Meta.id);
    }
}
