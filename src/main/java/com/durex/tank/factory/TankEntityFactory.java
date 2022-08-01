package com.durex.tank.factory;

import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.entity.EntityFactory;
import com.almasb.fxgl.entity.SpawnData;
import com.almasb.fxgl.entity.Spawns;
import com.durex.tank.component.TankComponent;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;

public class TankEntityFactory implements EntityFactory {

    @Spawns(value = GameConfig.PLAYER)
    public Entity newPlayer(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.PLAYER)
                .with(new TankComponent())
                .viewWithBBox("tank/H1U.png")
                .build() ;
    }
}
