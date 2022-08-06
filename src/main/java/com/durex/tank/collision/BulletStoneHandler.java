package com.durex.tank.collision;

import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.physics.CollisionHandler;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;

public class BulletStoneHandler extends CollisionHandler {

    public BulletStoneHandler() {
        super(GameType.BULLET, GameType.STONE);
    }

    @Override
    protected void onCollisionBegin(Entity bullet, Entity stone) {
        int level = bullet.getInt(GameConfig.LEVEL);
        if (level == GameConfig.TANK_MAX_LEVEL) {
            stone.removeFromWorld();
        }
        bullet.removeFromWorld();
    }
}
