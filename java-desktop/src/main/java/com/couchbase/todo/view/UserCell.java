package com.couchbase.todo.view;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ContextMenu;
import javafx.scene.control.Label;
import javafx.scene.control.ListCell;
import javafx.scene.control.MenuItem;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import org.jetbrains.annotations.NotNull;

import com.couchbase.todo.model.User;

public class UserCell extends ListCell<User> {

    public interface UserCellListener {
        void onUserCellDeleteMenuSelected(@NotNull User user);
    }

    @FXML private AnchorPane pane;

    @FXML private ImageView imageView;

    @FXML private Label nameLabel;

    @FXML private CheckBox completeCheckbox;

    @FXML private Button moreButton;

    private FXMLLoader loader;

    private User user;

    private UserCellListener listener;

    public UserCell(@NotNull UserCellListener listener) {
        this.listener = listener;
    }

    @Override
    protected void updateItem(User user, boolean empty) {
        super.updateItem(user, empty);

        this.user = user;

        if (empty || user == null) {
            setText(null);
            setContextMenu(null);
            return;
        }

        setText(user.getName());

        setupContextMenu();
    }

    private void setupContextMenu() {
        ContextMenu menu = getContextMenu();
        if (menu != null) return;

        MenuItem delete = new MenuItem("Delete");
        delete.setOnAction(event -> {
            if (this.listener != null) {
                this.listener.onUserCellDeleteMenuSelected(this.user);
            }
        });

        menu = new ContextMenu(delete);
        setContextMenu(menu);
    }

}
