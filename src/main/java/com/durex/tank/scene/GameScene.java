package com.durex.tank.scene;

import com.durex.tank.Director;
import com.durex.tank.enums.DirectionEnum;
import com.durex.tank.enums.GroupEnum;
import com.durex.tank.sprite.Background;
import com.durex.tank.sprite.Tank;
import javafx.animation.AnimationTimer;
import javafx.event.EventHandler;
import javafx.scene.canvas.Canvas;
import javafx.scene.input.KeyCode;
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
    private Tank self;
    private boolean up, down, left, right;

    public void init(Stage stage) {
        this.running = true;
        this.canvas = new Canvas(Director.WIDTH, Director.HEIGHT);
        this.background = new Background();
        this.self = Tank.builder()
                .x(400.0)
                .y(500.0)
                .speed(10)
                .group(GroupEnum.GREEN)
                .direction(DirectionEnum.UP)
                .gameScene(this)
                .build();

        this.keyProcess = keyEvent -> {
            if (keyEvent.getEventType() == KeyEvent.KEY_PRESSED) {
                switch (keyEvent.getCode()) {
                    case UP -> up = true;
                    case DOWN -> down = true;
                    case LEFT -> left = true;
                    case RIGHT -> right = true;
                }
            } else if (keyEvent.getEventType() == KeyEvent.KEY_RELEASED) {
                switch (keyEvent.getCode()) {
                    case UP -> up = false;
                    case DOWN -> down = false;
                    case LEFT -> left = false;
                    case RIGHT -> right = false;
                    case SPACE -> running = !running;
                }
            }
            if (running && keyEvent.getCode() != KeyCode.SPACE) {
                setSelfTankDirect();
                self.move();
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
        stage.getScene().setOnKeyPressed(keyProcess);
        refresh.start();
    }

    public void clear(Stage stage) {
        stage.getScene().removeEventHandler(KeyEvent.KEY_RELEASED, keyProcess);
        refresh.stop();
    }

    private void paint() {
        background.paint(canvas.getGraphicsContext2D());
        self.paint(canvas.getGraphicsContext2D());
    }

    private void setSelfTankDirect() {
        if (up && !down && !left && !right) {
            self.setDirection(DirectionEnum.UP);
        }
        if (!up && down && !left && !right) {
            self.setDirection(DirectionEnum.DOWN);
        }
        if (!up && !down && left && !right) {
            self.setDirection(DirectionEnum.LEFT);
        }
        if (!up && !down && !left && right) {
            self.setDirection(DirectionEnum.RIGHT);
        }
    }
}
