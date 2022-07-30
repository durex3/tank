package com.durex.tank.scene;

import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.stage.Stage;

import java.io.IOException;
import java.util.Objects;

/**
 * <h1>首页场景</h1>
 *
 * @author liugelong
 * @date 2022/7/24 15:06
 */
public class IndexScene {

    private IndexScene() {
    }

    /**
     * <h2>加载首页场景</h2>
     *
     * @param stage 主窗口
     */
    public static void load(Stage stage) {
        try {
            Parent root = FXMLLoader.load(Objects.requireNonNull(IndexScene.class.getResource("/com/durex/tank/index.fxml")));
            stage.getScene().setRoot(root);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
