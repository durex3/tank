package com.durex.tank.collision;

import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.physics.CollisionHandler;
import com.durex.tank.enums.GameType;

public class BulletBrickHandler  extends CollisionHandler {

    public BulletBrickHandler() {
        super(GameType.BULLET, GameType.BRICK);
    }

    @Override
    protected void onCollisionBegin(Entity bullet, Entity brick) {
        bullet.removeFromWorld();
        brick.removeFromWorld();
    }
}
