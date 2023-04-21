

module com.couchbase.todo {
    requires javafx.fxml;
    requires javafx.controls;

    requires org.jetbrains.annotations;

    requires couchbase.lite.java.ee;
    requires okhttp3;

    opens com.couchbase.todo to javafx.fxml;
    opens com.couchbase.todo.view to javafx.fxml;
    opens com.couchbase.todo.controller to javafx.fxml;

    exports com.couchbase.todo;
 }
