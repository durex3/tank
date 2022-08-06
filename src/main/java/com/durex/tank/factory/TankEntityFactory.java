package com.durex.tank.factory;

import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.dsl.components.ExpireCleanComponent;
import com.almasb.fxgl.dsl.components.HealthIntComponent;
import com.almasb.fxgl.dsl.components.ProjectileComponent;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.entity.EntityFactory;
import com.almasb.fxgl.entity.SpawnData;
import com.almasb.fxgl.entity.Spawns;
import com.almasb.fxgl.entity.components.CollidableComponent;
import com.almasb.fxgl.physics.BoundingShape;
import com.almasb.fxgl.texture.AnimatedTexture;
import com.almasb.fxgl.texture.AnimationChannel;
import com.almasb.fxgl.ui.ProgressBar;
import com.durex.tank.component.EnemyComponent;
import com.durex.tank.component.TankComponent;
import com.durex.tank.component.TankLevelComponent;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.GameType;
import javafx.geometry.Point2D;
import javafx.scene.paint.Color;
import javafx.scene.shape.Rectangle;
import javafx.util.Duration;

public class TankEntityFactory implements EntityFactory {

    @Spawns(value = GameConfig.PLAYER)
    public Entity player(SpawnData data) {

        HealthIntComponent health = new HealthIntComponent(GameConfig.PLAYER_MAX_HEALTH);
        health.setValue(GameConfig.PLAYER_MAX_HEALTH);
        ProgressBar healthBar = new ProgressBar(false);
        healthBar.setWidth(39);
        healthBar.setTranslateY(40);
        healthBar.setFill(Color.LIGHTGREEN);
        healthBar.currentValueProperty().addListener((observableValue, oldValue, newValue) -> {
            if (newValue.intValue() <= GameConfig.PLAYER_MAX_HEALTH * 0.4) {
                healthBar.setFill(Color.RED);
            } else if (newValue.intValue() <= GameConfig.PLAYER_MAX_HEALTH * 0.8) {
                healthBar.setFill(Color.YELLOW);
            } else {
                healthBar.setFill(Color.LIGHTGREEN);
            }
        });

        healthBar.maxValueProperty().bind(health.maxValueProperty());
        healthBar.currentValueProperty().bind(health.valueProperty());

        return FXGL.entityBuilder(data)
                .type(GameType.PLAYER)
                .viewWithBBox("tank/H1U.png")
                .view(healthBar)
                .with(new TankComponent())
                .with(new TankLevelComponent())
                .with(health)
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
                .build();
    }

    @Spawns(value = GameConfig.SNOW)
    public Entity snow(SpawnData data) {
        return FXGL.entityBuilder(data)
                .type(GameType.SNOW)
                .with(new TankComponent())
                .viewWithBBox("map/snow.png")
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
        FXGL.play("normalFire.wav");
        final Point2D direct = data.get(GameConfig.DIRECT);
        GameType gameType = data.<GameType>get(GameConfig.OWNER_TYPE);

        CollidableComponent collidableComponent = new CollidableComponent(true);
        collidableComponent.addIgnoredType(gameType);

        return FXGL.entityBuilder(data)
                .type(GameType.BULLET)
                .viewWithBBox("bullet/normal.png")
                .with(new ProjectileComponent(direct, GameConfig.BULLET_SPEED))
                .with(collidableComponent)
                .build();
    }

    @Spawns(value = GameConfig.ENEMY)
    public Entity enemy(SpawnData data) {

        int random = FXGL.random(1, 12);

        HealthIntComponent health = new HealthIntComponent(random);
        health.setValue(random);
        ProgressBar healthBar = new ProgressBar(false);
        healthBar.setWidth(35);
        healthBar.setTranslateY(41);
        healthBar.setFill(Color.LIGHTGREEN);
        healthBar.maxValueProperty().bind(health.maxValueProperty());
        healthBar.currentValueProperty().bind(health.valueProperty());
        healthBar.currentValueProperty().addListener((observableValue, oldValue, newValue) -> {
            if (newValue.intValue() <= random * 0.4) {
                healthBar.setFill(Color.RED);
            } else if (newValue.intValue() <= random * 0.8) {
                healthBar.setFill(Color.YELLOW);
            } else {
                healthBar.setFill(Color.LIGHTGREEN);
            }
        });

        return FXGL.entityBuilder(data)
                .type(GameType.ENEMY)
                .with(new TankComponent())
                .with(new EnemyComponent())
                .with(new TankLevelComponent())
                .with(health)
                .view(healthBar)
                .viewWithBBox("tank/E" + random + "U.png")
                .collidable()
                .build();
    }

    @Spawns(value = GameConfig.EXPLODE)
    public Entity explode(SpawnData data) {
        FXGL.play("normalBomb.wav");
        AnimationChannel channel = new AnimationChannel(
                FXGL.image("explode/explode_level_1.png"),
                GameConfig.EXPLODE_TIME,
                5);
        AnimatedTexture texture = new AnimatedTexture(channel);
        return FXGL.entityBuilder(data)
                .view(texture.play())
                .with(new ExpireCleanComponent(GameConfig.EXPLODE_TIME))
                .build();
    }
}
