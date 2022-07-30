package com.durex.tank.scene;

import com.durex.tank.Director;
import com.durex.tank.sprite.Background;
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

    private Canvas canvas;
    private boolean running;
    private Background background;
    private EventHandler<KeyEvent> keyProcess;
    private AnimationTimer refresh;

    public void init(Stage stage) {
        this.running = true;
        this.canvas = new Canvas(Director.WIDTH, Director.HEIGHT);
        this.background = new Background();

        this.keyProcess = keyEvent -> {
            switch (keyEvent.getCode()) {
                case SPACE -> running = !running;
                default -> System.out.println("default");
            }
        };
        this.refresh = new AnimationTimer() {
            @Override
            public void handle(long now) {
                if (running) {
                    paint();
                }
            }
        };

        AnchorPane root = new AnchorPane(canvas);
        stage.getScene().setRoot(root);
        stage.getScene().setOnKeyReleased(keyProcess);
        refresh.start();
    }

    public void clear(Stage stage) {
        stage.getScene().removeEventHandler(KeyEvent.KEY_RELEASED, keyProcess);
        refresh.stop();
    }

    private void paint() {
        background.paint(canvas.getGraphicsContext2D());
    }
}
