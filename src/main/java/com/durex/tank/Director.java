package com.durex.tank;

import com.durex.tank.scene.GameScene;
import com.durex.tank.scene.IndexScene;
import com.durex.tank.utils.FileUtils;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.scene.layout.AnchorPane;
import javafx.stage.Stage;

/**
 * <h1>导演类</h1>
 *
 * @author liugelong
 * @date 2022/7/24 13:54
 */
public class Director {

    private static final Director INSTANCE = new Director();
    public static final int WIDTH = 960;
    public static final int HEIGHT = 640;
    private Stage stage;
    private GameScene gameScene;

    private Director() {
    }

    public static Director getInstance() {
        return INSTANCE;
    }

    public void init(Stage stage) {
        this.gameScene = new GameScene();
        initStage(stage);
        toIndex();
    }

    /**
     * <h2>跳转首页</h2>
     */
    public void toIndex() {
        IndexScene.load(stage);
    }

    /**
     * <h2>游戏开始</h2>
     */
    public void gameStart() {
        gameScene.init(stage);
    }

    /**
     * <h2>游戏结束</h2>
     */
    public void gameOver() {

    }

    /**
     * <h2>初始化窗口</h2>
     *
     * @param stage 窗口
     */
    private void initStage(Stage stage) {
        this.stage = stage;
        AnchorPane root = new AnchorPane();
        Scene scene = new Scene(root, WIDTH, HEIGHT);
        stage.setTitle("坦克大战");
        final Image logo = new Image("/logo.png");
        stage.getIcons().add(logo);
        stage.setResizable(false);
        stage.setScene(scene);
        stage.setWidth(WIDTH);
        stage.setHeight(HEIGHT);
        stage.show();
    }
}
