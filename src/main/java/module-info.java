module com.durex.tank {
    requires javafx.controls;
    requires javafx.fxml;

    opens com.durex.tank to javafx.fxml;
    opens com.durex.tank.controller to javafx.fxml;

    exports com.durex.tank;
    exports com.durex.tank.controller;

}