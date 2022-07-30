package com.durex.tank.scene;

import com.durex.tank.Director;
import javafx.animation.AnimationTimer;
import javafx.event.EventHandler;
import javafx.scene.canvas.Canvas;
import javafx.scene.input.KeyEvent;
import javafx.scene.layout.AnchorPane;
import javafx.stage.Stage;

/**
 * <h1>游戏场景</h1>
 *
 * @author liugelong
 * @date 2022/7/30 13:35
 */
public class GameScene {

    private Canvas canvas = new Canvas(Director.WIDTH, Director.HEIGHT);
    private boolean running;

    private final EventHandler<KeyEvent> keyProcess = keyEvent -> {
        switch (keyEvent.getCode()) {
            case SPACE -> running = !running;
            default -> System.out.println("default");
        }
    };

    private final AnimationTimer refresh = new AnimationTimer() {
        @Override
        public void handle(long now) {
            if (running) {
                paint();
            }
        }
    };

    public void init(Stage stage) {
        AnchorPane root = new AnchorPane();
        stage.getScene().setRoot(root);
        stage.getScene().setOnKeyReleased(keyProcess);
        refresh.start();
    }

    public void clear(Stage stage) {
        stage.getScene().removeEventHandler(KeyEvent.KEY_RELEASED, keyProcess);
        refresh.stop();
    }

    private void paint() {

    }
}
