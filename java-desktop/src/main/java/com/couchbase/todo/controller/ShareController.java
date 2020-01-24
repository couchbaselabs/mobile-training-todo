package com.couchbase.todo.controller;

import java.net.URL;
import java.util.ResourceBundle;
import java.util.concurrent.atomic.AtomicBoolean;

import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.Expression;
import com.couchbase.lite.Meta;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.MutableDocument;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.model.DB;
import com.couchbase.todo.model.service.DeleteDocService;
import com.couchbase.todo.model.service.SaveDocService;
import com.couchbase.todo.model.TaskList;
import com.couchbase.todo.model.User;
import com.couchbase.todo.view.UserCell;


public class ShareController implements Initializable, UserCell.UserCellListener {

    static final String TYPE = "task-list.user";
    static final String KEY_TYPE = "type";
    static final String KEY_USERNAME = "username";
    static final String KEY_TASK_LIST = "taskList";
    static final String KEY_ID = "id";
    static final String KEY_OWNER = "owner";
    static final String KEY_TASK_LIST_ID = "taskList.id";

    @FXML private TextField userNameTextField;

    @FXML private Button addUserButton;

    @FXML private ListView<User> listView;

    private final AtomicBoolean initialized = new AtomicBoolean();

    private @NotNull TaskList taskList;

    private @NotNull Query query;

    public ShareController(@NotNull TaskList taskList) {
        this.taskList = taskList;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        registerEventHandlers();
        listView.setItems(FXCollections.observableArrayList());
        listView.setCellFactory(listView -> new UserCell(this));
        getUserList();
    }

    public void close() {
        DB.get().removeChangeListeners(query);
    }

    private void registerEventHandlers() {
        addUserButton.setOnAction(event -> {
            String username = userNameTextField.getText();
            if (username.trim().length() > 0) {
                addUser(username);
            }
        });
    }

    private void getUserList() {
        query = QueryBuilder.select(
            SelectResult.expression(Meta.id),
            SelectResult.property(KEY_USERNAME))
            .from(DB.get().getDataSource())
            .where(Expression.property(KEY_TYPE).equalTo(Expression.string(TYPE)).and(
                Expression.property(KEY_TASK_LIST_ID).equalTo(Expression.string(taskList.getId()))));

        DB.get().addChangeListener(query, change -> {
            ObservableList<User> users = FXCollections.observableArrayList();
            for (Result r : change.getResults()) {
                User user = new User(
                    r.getString(0),
                    r.getString(1));
                users.add(user);
            }

            Platform.runLater(() -> {
                listView.setItems(users);
            });
        });
    }

    private void addUser(@NotNull String username) {
        MutableDocument doc = new MutableDocument(taskList.getId() + "." + username);
        doc.setValue(KEY_TYPE, TYPE);
        doc.setValue(KEY_USERNAME, username);

        MutableDictionary taskListInfo = new MutableDictionary();
        taskListInfo.setValue(KEY_ID, taskList.getId());
        taskListInfo.setValue(KEY_OWNER, taskList.getOwner());
        doc.setValue(KEY_TASK_LIST, taskListInfo);

        new SaveDocService(doc).start();
    }

    private void deleteUser(@NotNull User user) {
        new DeleteDocService(user.getId()).start();
    }

    // UserCellListener

    @Override
    public void onUserCellDeleteMenuSelected(@NotNull User user) {
        deleteUser(user);
    }

}
