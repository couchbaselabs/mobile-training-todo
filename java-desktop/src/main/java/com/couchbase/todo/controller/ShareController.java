package com.couchbase.todo.controller;

import java.net.URL;
import java.util.Objects;
import java.util.ResourceBundle;

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
import com.couchbase.lite.Ordering;
import com.couchbase.lite.Query;
import com.couchbase.lite.QueryBuilder;
import com.couchbase.lite.Result;
import com.couchbase.lite.SelectResult;
import com.couchbase.todo.model.DB;
import com.couchbase.todo.model.TaskList;
import com.couchbase.todo.model.User;
import com.couchbase.todo.model.service.DeleteDocService;
import com.couchbase.todo.model.service.SaveDocService;
import com.couchbase.todo.view.UserCell;


public class ShareController implements Initializable, UserCell.UserCellListener {

    @FXML
    private TextField userNameTextField;

    @FXML
    private Button addUserButton;

    @FXML
    private ListView<User> listView;

    @NotNull
    private final TaskList taskList;

    @SuppressWarnings("NotNullFieldNotInitialized")
    @NotNull
    private Query query;

    public ShareController(@NotNull TaskList taskList) { this.taskList = taskList; }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        registerEventHandlers();
        listView.setItems(FXCollections.observableArrayList());
        listView.setCellFactory(listView -> new UserCell(this));
        getUserList();
    }

    public void close() { DB.get().removeChangeListeners(query); }

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
                SelectResult.property(DB.KEY_USERNAME))
            .from(DB.get().getDataSource(DB.COLLECTION_USERS))
            .where(Expression.property(DB.KEY_PARENT_LIST_ID).equalTo(Expression.string(taskList.getId())))
            .orderBy(Ordering.property(DB.KEY_USERNAME));

        DB.get().addChangeListener(
            query,
            change -> {
                ObservableList<User> users = FXCollections.observableArrayList();
                assert change.getResults() != null;
                for (Result r: change.getResults()) {
                    User user = new User(
                        Objects.requireNonNull(r.getString(0)),
                        Objects.requireNonNull(r.getString(1)));
                    users.add(user);
                }

                Platform.runLater(() -> listView.setItems(users));
            });
    }

    private void addUser(@NotNull String username) {
        String listId = taskList.getId();

        MutableDocument doc = new MutableDocument(listId + "." + username);
        doc.setValue(DB.KEY_USERNAME, username);

        MutableDictionary taskListInfo = new MutableDictionary();
        taskListInfo.setValue(DB.KEY_ID, listId);
        taskListInfo.setValue(DB.KEY_OWNER, taskList.getOwner());
        doc.setValue(DB.KEY_TASK_LIST, taskListInfo);

        System.out.println("###### NEW USER: " + username + " for list " + listId);

        new SaveDocService(DB.COLLECTION_USERS, doc).start();
    }

    private void deleteUser(@NotNull User user) {
        new DeleteDocService(DB.COLLECTION_USERS, user.getId()).start();
    }

    // UserCellListener

    @Override
    public void onUserCellDeleteMenuSelected(@NotNull User user) { deleteUser(user); }
}
