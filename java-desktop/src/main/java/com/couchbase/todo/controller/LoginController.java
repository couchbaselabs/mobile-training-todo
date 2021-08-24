package com.couchbase.todo.controller;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;
import javafx.stage.Stage;
import org.jetbrains.annotations.NotNull;

import com.couchbase.todo.TodoApp;
import com.couchbase.todo.model.DB;


public class LoginController implements Initializable {

    @FXML
    private TextField userNameField;

    @FXML
    private PasswordField passwordField;

    @FXML
    private Button signInButton;

    @FXML
    private CheckBox loggingCheckbox;

    @NotNull
    private final Stage stage;

    public LoginController(@NotNull Stage stage) {
        this.stage = stage;
    }

    @Override
    public void initialize(URL location, ResourceBundle resources) { registerEventHandlers(); }

    private void registerEventHandlers() {
        signInButton.setOnAction(event -> {
            String username = userNameField.getText();
            String password = passwordField.getText();
            if (username.trim().length() > 0 && password.trim().length() > 0) {
                DB.get().login(username, password);
                TodoApp.goToPage(this.stage, TodoApp.MAIN_FXML);
            }
        });
    }
}
