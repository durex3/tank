package com.durex.tank;

import com.almasb.fxgl.app.CursorInfo;
import com.almasb.fxgl.app.GameApplication;
import com.almasb.fxgl.app.GameSettings;
import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.entity.Entity;
import com.durex.tank.component.TankComponent;
import com.durex.tank.config.GameConfig;
import com.durex.tank.factory.TankEntityFactory;
import javafx.geometry.Point2D;
import javafx.scene.input.KeyCode;
import javafx.scene.paint.Color;

public class TankApplication extends GameApplication {

    private Entity player;

    @Override
    protected void initSettings(GameSettings gameSettings) {
        gameSettings.setTitle(GameConfig.TITLE);
        gameSettings.setVersion(GameConfig.VERSION);
        gameSettings.setWidth(28 * GameConfig.CELL_SIZE + 6 * GameConfig.CELL_SIZE);
        gameSettings.setHeight(28 * GameConfig.CELL_SIZE);
        gameSettings.setAppIcon("icon.png");
        gameSettings.setDefaultCursor(new CursorInfo("cursor.png", 0, 0));
    }

    @Override
    protected void initGame() {
        // 1. 设置游戏的背景色
        FXGL.getGameScene().setBackgroundColor(Color.BLACK);

        // 2. 指定创建游戏实体的工厂类
        FXGL.getGameWorld().addEntityFactory(new TankEntityFactory());

        // 3. 地图
        FXGL.setLevelFromMap("level1.tmx");

        player = FXGL.spawn(GameConfig.PLAYER);
        // 4. 初始化玩家坦克的位置
        player.setPosition(new Point2D(10 * GameConfig.CELL_SIZE, 27 * GameConfig.CELL_SIZE - player.getWidth() - 1));
    }

    @Override
    protected void initInput() {
        FXGL.onKey(KeyCode.UP, () -> {
            TankComponent component = player.getComponent(TankComponent.class);
            component.moveUp();
        });
        FXGL.onKey(KeyCode.DOWN, () -> {
            TankComponent component = player.getComponent(TankComponent.class);
            component.moveDown();
        });
        FXGL.onKey(KeyCode.LEFT, () -> {
            TankComponent component = player.getComponent(TankComponent.class);
            component.moveLeft();
        });
        FXGL.onKey(KeyCode.RIGHT, () -> {
            TankComponent component = player.getComponent(TankComponent.class);
            component.moveRight();
        });
        FXGL.onKey(KeyCode.A, () -> {
            TankComponent component = player.getComponent(TankComponent.class);
            component.shoot();
        });
    }

    public static void main(String[] args) {
        GameApplication.launch(args);
    }
}