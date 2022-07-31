package com.durex.tank;

import com.almasb.fxgl.app.CursorInfo;
import com.almasb.fxgl.app.GameApplication;
import com.almasb.fxgl.app.GameSettings;
import com.almasb.fxgl.dsl.FXGL;
import com.durex.tank.config.GameConfig;
import com.durex.tank.factory.TankEntityFactory;
import javafx.scene.paint.Color;

public class TankApplication extends GameApplication {

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
        FXGL.spawn(GameConfig.PLAYER);
    }

    public static void main(String[] args) {
        TankApplication.launch(args);
    }
}
