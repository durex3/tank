package com.durex.tank.factory;

import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.entity.EntityFactory;
import com.almasb.fxgl.entity.SpawnData;
import com.almasb.fxgl.entity.Spawns;
import com.almasb.fxgl.texture.AnimatedTexture;
import com.almasb.fxgl.texture.AnimationChannel;
import com.durex.tank.component.TankComponent;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;
import javafx.util.Duration;

public class TankEntityFactory implements EntityFactory {

    @Spawns(value = GameConfig.PLAYER)
    public Entity player(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.PLAYER)
                .with(new TankComponent())
                .viewWithBBox("tank/H1U.png")
                .collidable()
                .build();
    }

    @Spawns(value = GameConfig.BRICK)
    public Entity brick(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.BRICK)
                .with(new TankComponent())
                .viewWithBBox("map/brick.png")
                .collidable()
                .build();
    }

    @Spawns(value = GameConfig.GREENS)
    public Entity greens(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.GREENS)
                .with(new TankComponent())
                .viewWithBBox("map/greens.png")
                .collidable()
                .neverUpdated()
                .zIndex(1000)
                .build();
    }

    @Spawns(value = GameConfig.SEA)
    public Entity sea(SpawnData data) {
        AnimationChannel animationChannel = new AnimationChannel(
                FXGL.image("map/sea_anim.png"),
                Duration.seconds(1),
                2
        );
        AnimatedTexture texture = new AnimatedTexture(animationChannel);
        return FXGL.entityBuilder(data)
                .type(GameType.SEA)
                .with(new TankComponent())
                .viewWithBBox(texture.loop())
                .collidable()
                .build();
    }

    @Spawns(value = GameConfig.SNOW)
    public Entity snow(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.SNOW)
                .with(new TankComponent())
                .viewWithBBox("map/snow.png")
                .collidable()
                .neverUpdated()
                .build();
    }

    @Spawns(value = GameConfig.STONE)
    public Entity stone(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.STONE)
                .with(new TankComponent())
                .viewWithBBox("map/stone.png")
                .collidable()
                .neverUpdated()
                .build();
    }
}
