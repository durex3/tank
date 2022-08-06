package com.durex.tank.collision;

import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.physics.CollisionHandler;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;

public class BulletBulletHandler extends CollisionHandler {

    public BulletBulletHandler() {
        super(GameType.BULLET, GameType.BULLET);
    }

    @Override
    protected void onCollisionBegin(Entity bulletA, Entity bulletB) {
        GameType ownerTypeA = bulletA.getObject(GameConfig.OWNER_TYPE);
        GameType ownerTypeB = bulletB.getObject(GameConfig.OWNER_TYPE);
        // 发生子弹的对象是不同的
        if (ownerTypeA != ownerTypeB) {
            bulletA.removeFromWorld();
            bulletB.removeFromWorld();
        }
    }
}
