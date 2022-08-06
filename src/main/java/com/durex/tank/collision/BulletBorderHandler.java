package com.durex.tank.collision;

import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.physics.CollisionHandler;
import com.durex.tank.enums.GameType;

public class BulletBorderHandler extends CollisionHandler {

    public BulletBorderHandler() {
        super(GameType.BULLET, GameType.BORDER);
    }

    @Override
    protected void onCollisionBegin(Entity bullet, Entity border) {
        bullet.removeFromWorld();
    }
}
