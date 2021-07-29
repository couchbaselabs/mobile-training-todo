package com.couchbase.todo.controller;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.TextField;
import javafx.stage.Stage;
import org.jetbrains.annotations.NotNull;

import com.couchbase.lite.internal.core.CBLVersion;
import com.couchbase.todo.TodoApp;
import com.couchbase.todo.model.Config;
import com.couchbase.todo.model.DB;


public class ConfigController implements Initializable {
    private @NotNull Stage stage;

    @FXML
    private CheckBox loggingCheckbox;
    @FXML
    private CheckBox loginCheckbox;
    @FXML
    private CheckBox localCheckbox;
    @FXML
    private CheckBox remoteCheckbox;
    @FXML
    private TextField cblVersionTextField;
    @FXML
    private TextField dbNameTextField;
    @FXML
    private TextField sgUrlTextField;
    @FXML
    private TextField maxRetriesTextField;
    @FXML
    private TextField waitTimeTextField;
    @FXML
    private Button saveButton;
    @FXML
    private Button cancelButton;


    public ConfigController(@NotNull Stage stage) { this.stage = stage; }

    @Override
    public void initialize(URL location, ResourceBundle resources) {
        //set initial values of checkbox and text field
        RegisterButtonEventHandler();

        cblVersionTextField.setText(CBLVersion.getVersionInfo());

        loggingCheckbox.setSelected(TodoApp.getConfig().isLoggingEnabled());
        loginCheckbox.setSelected(TodoApp.getConfig().isLoginRequired());

        setCcrState(TodoApp.getConfig().getCr_mode());

        dbNameTextField.setText(TodoApp.getConfig().getDbName());
        sgUrlTextField.setText(TodoApp.getConfig().getSgwUri());
        maxRetriesTextField.setText(String.valueOf(TodoApp.getConfig().getAttempts()));
        waitTimeTextField.setText(String.valueOf(TodoApp.getConfig().getAttemptsWaitTime()));
    }

    private void RegisterButtonEventHandler() {
        // handle events clicking cancel button and save buttons
        cancelButton.setOnAction(event -> {
            TodoApp.goToPage(this.stage, TodoApp.MAIN_FXML);
        });

        saveButton.setOnAction(event -> {
            update();
            TodoApp.goToPage(this.stage, TodoApp.LOGIN_FXML);
        });
    }

    private void update() {
        String eDbName = (dbNameTextField.getText().isEmpty()) ? null : dbNameTextField.getText();
        String eSgUri = (sgUrlTextField.getText().isEmpty()) ? null : sgUrlTextField.getText();
        String eAttempts = (maxRetriesTextField.getText().isEmpty()) ? "0" : maxRetriesTextField.getText();
        String eWaitTime = (waitTimeTextField.getText().isEmpty()) ? "0" : waitTimeTextField.getText();
        TodoApp.CR_MODE mode = getCcrState();
        boolean logging = loggingCheckbox.isSelected();
        boolean login = loginCheckbox.isSelected();

        Config newConfig = Config.builder().logging(logging).login(login).dbName(eDbName).sgwUri(eSgUri)
            .attempts(Integer.parseInt(eAttempts)).waitTime(Integer.parseInt(eWaitTime)).mode(mode).build();

        TodoApp.setConfig(newConfig);
        DB.get().logout();
    }

    private TodoApp.CR_MODE getCcrState() {
        return (remoteCheckbox.isSelected())
            ? TodoApp.CR_MODE.REMOTE
            : ((localCheckbox.isSelected())
                ? TodoApp.CR_MODE.LOCAL
                : TodoApp.CR_MODE.DEFAULT);
    }

    private void setCcrState(TodoApp.CR_MODE mode) {
        localCheckbox.setSelected(mode == TodoApp.CR_MODE.LOCAL);
        remoteCheckbox.setSelected(mode == TodoApp.CR_MODE.REMOTE);
    }
}
