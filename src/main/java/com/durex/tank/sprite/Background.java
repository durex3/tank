package com.durex.tank.sprite;

import com.durex.tank.Director;
import com.durex.tank.scene.GameScene;
import javafx.scene.image.Image;

public class Background extends Sprite {

    public Background() {
        super(new Image("/LevelsBackground.jpg"), 0.0, 0.0, (double) Director.WIDTH, (double) Director.HEIGHT);
    }

    @Override
    public void destroy() {

    }
}
