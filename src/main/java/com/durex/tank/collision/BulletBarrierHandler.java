package com.durex.tank.collision;

import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.physics.CollisionHandler;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;

import java.util.List;

public class BulletBarrierHandler extends CollisionHandler {

    public BulletBarrierHandler(GameType type) {
        super(GameType.BULLET, type);
    }

    @Override
    protected void onCollision(Entity bullet, Entity barrier) {
        List<Entity> entityList = FXGL.getGameWorld().getEntitiesFiltered(
                entity -> bullet.isColliding(entity) &&
                        (entity.isType(GameType.BRICK) || entity.isType(GameType.STONE) || entity.isType(GameType.GREENS))
        );
        if (entityList.isEmpty()) {
            return;
        }
        boolean isRemoveBullet = false;
        for (Entity entity : entityList) {
            GameType type = (GameType) entity.getType();
            switch (type) {
                case BRICK -> {
                    entity.removeFromWorld();
                    isRemoveBullet = true;
                }
                case STONE -> {
                    int level = bullet.getInt(GameConfig.LEVEL);
                    if (level == GameConfig.TANK_MAX_LEVEL) {
                        entity.removeFromWorld();
                    }
                    isRemoveBullet = true;
                }
                case GREENS -> {
                    int level = bullet.getInt(GameConfig.LEVEL);
                    if (level == GameConfig.TANK_MAX_LEVEL) {
                        entity.removeFromWorld();
                    }
                }
            }
        }
        if (isRemoveBullet) {
            bullet.removeFromWorld();
        }
    }
}
