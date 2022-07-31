package com.durex.tank.factory;

import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.entity.EntityFactory;
import com.almasb.fxgl.entity.SpawnData;
import com.almasb.fxgl.entity.Spawns;
import com.durex.tank.config.GameConfig;

public class TankEntityFactory implements EntityFactory {

    @Spawns(value = GameConfig.PLAYER)
    public Entity newPlayer(SpawnData data) {
        return FXGL.entityBuilder(data)
                .build() ;
    }
}
