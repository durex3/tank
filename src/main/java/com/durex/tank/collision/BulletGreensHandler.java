package com.durex.tank.collision;

import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.physics.CollisionHandler;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;

public class BulletGreensHandler extends CollisionHandler {

    public BulletGreensHandler() {
        super(GameType.BULLET, GameType.GREENS);
    }

    @Override
    protected void onCollisionBegin(Entity bullet, Entity greens) {
        int level = bullet.getInt(GameConfig.LEVEL);
        if (level == GameConfig.TANK_MAX_LEVEL) {
            greens.removeFromWorld();
        }
    }
}
