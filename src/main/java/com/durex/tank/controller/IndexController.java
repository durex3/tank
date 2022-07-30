package com.durex.tank.controller;

import com.durex.tank.Director;
import com.durex.tank.sound.SoundEffect;
import javafx.fxml.FXML;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;

/**
 * @author liugelong
 * @date 2022/7/24 23:11
 */
public class IndexController {

    @FXML
    private ImageView startGame;

    @FXML
    void mouseClickedStartGame(MouseEvent event) {
        SoundEffect.play("/done.wav");
        Director.getInstance().gameStart();
    }

    @FXML
    void mouseEnteredStartGame(MouseEvent event) {
        startGame.setOpacity(0.75);
        SoundEffect.play("/button.wav");
    }

    @FXML
    void mouseExitedStartGame(MouseEvent event) {
        startGame.setOpacity(1);
    }
}
