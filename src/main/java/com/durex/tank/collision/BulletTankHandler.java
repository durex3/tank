package com.durex.tank.collision;

import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.dsl.components.HealthIntComponent;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.entity.SpawnData;
import com.almasb.fxgl.physics.CollisionHandler;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;

public class BulletTankHandler extends CollisionHandler {

    public BulletTankHandler(GameType tank) {
        super(GameType.BULLET, tank);
    }

    @Override
    protected void onCollisionBegin(Entity bullet, Entity tank) {
        HealthIntComponent health = tank.getComponent(HealthIntComponent.class);
        health.damage(1);
        if (health.isZero()) {
            FXGL.spawn(GameConfig.EXPLODE, new SpawnData(tank.getCenter().subtract(50.0 / 2, 50.0 / 2)));
            tank.removeFromWorld();
        }
        bullet.removeFromWorld();
    }
}
