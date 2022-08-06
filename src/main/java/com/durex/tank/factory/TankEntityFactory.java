package com.durex.tank.factory;

import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.dsl.components.ProjectileComponent;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.entity.EntityFactory;
import com.almasb.fxgl.entity.SpawnData;
import com.almasb.fxgl.entity.Spawns;
import com.almasb.fxgl.physics.BoundingShape;
import com.almasb.fxgl.texture.AnimatedTexture;
import com.almasb.fxgl.texture.AnimationChannel;
import com.durex.tank.component.EnemyComponent;
import com.durex.tank.component.TankComponent;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;
import javafx.geometry.Point2D;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
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
                .bbox(BoundingShape.box(GameConfig.CELL_SIZE, GameConfig.CELL_SIZE))
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
                .bbox(BoundingShape.box(GameConfig.CELL_SIZE, GameConfig.CELL_SIZE))
                .collidable()
                .neverUpdated()
                .build();
    }

    @Spawns(value = GameConfig.BORDER)
    public Entity border(SpawnData data) {
        int width = data.<Integer>get("width");
        int height = data.<Integer>get("height");
        return FXGL.entityBuilder(data)
                .type(GameType.BORDER)
                .viewWithBBox(new Rectangle(width, height, Color.LIGHTGRAY))
                .collidable()
                .neverUpdated()
                .build();
    }

    @Spawns(value = GameConfig.FLAG)
    public Entity flag(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.FLAG)
                .viewWithBBox("map/flag.png")
                .collidable()
                .build();
    }

    @Spawns(value = GameConfig.BULLET)
    public Entity bullet(SpawnData data) {
        final Point2D direct = data.get("direct");
        return FXGL.entityBuilder(data)
                .type(GameType.BULLET)
                .viewWithBBox("bullet/normal.png")
                .with(new ProjectileComponent(direct, GameConfig.BULLET_SPEED))
                .collidable()
                .build();
    }

    @Spawns(value = GameConfig.ENEMY)
    public Entity enemy(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.ENEMY)
                .with(new TankComponent())
                .with(new EnemyComponent())
                .viewWithBBox("tank/E" + FXGL.random(1, 10) + "U.png")
                .collidable()
                .build();
    }
}
