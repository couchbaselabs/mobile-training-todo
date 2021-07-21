package com.couchbase.todo.controller;

import java.net.URL;
import java.util.Objects;
import java.util.ResourceBundle;

import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.TextField;
import javafx.stage.Stage;
import org.jetbrains.annotations.NotNull;

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
        buttonsEventHandler();
        cblVersionTextField.setText("CBL Version?");

        loggingCheckbox.setSelected(Config.get().isLoggingEnabled());
        loginCheckbox.setSelected(Config.get().isLoginRequired());

        setCcrState(Config.get().getCr_mode());

        dbNameTextField.setText(Config.get().getDbName());
        sgUrlTextField.setText(Config.get().getSgUri());
        maxRetriesTextField.setText(String.valueOf(Config.get().getAttempts()));
        waitTimeTextField.setText(String.valueOf(Config.get().getAttemptsWaitTime()));
    }

    private void buttonsEventHandler() {
        // handle events clicking cancel button and save buttons
        cancelButton.setOnAction(event -> {
            TodoApp.gotoMainScreen(this.stage);
        });

        saveButton.setOnAction(event -> {
            update();
            TodoApp.gotoLoginScreen(this.stage);
        });
    }

    private void update() {
        String eDbName = (dbNameTextField.getText().isEmpty()) ? null : dbNameTextField.getText();
        String eSgUri = (sgUrlTextField.getText().isEmpty()) ? null : sgUrlTextField.getText();
        String eAttempts = (maxRetriesTextField.getText().isEmpty()) ? null : maxRetriesTextField.getText();
        String eTimeout = (waitTimeTextField.getText().isEmpty()) ? null : waitTimeTextField.getText();

        final boolean updated = Config.get().update(
            loggingCheckbox.isSelected(),
            loginCheckbox.isSelected(),
            getCcrState(),
            eDbName,
            eSgUri,
            Integer.parseInt(eAttempts),
            Integer.parseInt(eTimeout));

        if (updated) { DB.get().logout(); }
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
