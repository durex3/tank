module com.durex.tank {
    requires javafx.controls;
    requires javafx.fxml;


    opens com.durex.tank to javafx.fxml;
    exports com.durex.tank;
}