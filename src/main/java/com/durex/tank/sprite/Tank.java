package com.durex.tank.sprite;

import com.durex.tank.enums.DirectionEnum;
import com.durex.tank.enums.GroupEnum;
import com.durex.tank.scene.GameScene;
import javafx.scene.image.Image;

import java.util.Map;

public class Tank extends Role {

    private Tank(Builder builder) {
        super(builder.imageMap(), builder.x, builder.y, 60.0, 60.0, builder.group, builder.direction, builder.speed, builder.gameScene);
    }

    @Override
    public void move() {
        switch (this.getDirection()) {
            case UP -> this.setY(this.getY() - this.getSpeed());
            case DOWN ->this.setY(this.getY() + this.getSpeed());
            case LEFT ->  this.setX(this.getX() - this.getSpeed());
            case RIGHT -> this.setX(this.getX() + this.getSpeed());
        }
    }

    @Override
    public boolean isCollision(Sprite sprite) {
        return false;
    }

    @Override
    public void destroy() {

    }

    public static class Builder {
        private Double x;
        private Double y;
        private GameScene gameScene;
        private GroupEnum group;
        private DirectionEnum direction;
        private double speed;

        public Builder x(double x) {
            this.x = x;
            return this;
        }

        public Builder y(double y) {
            this.y = y;
            return this;
        }

        public Builder gameScene(GameScene gameScene) {
            this.gameScene = gameScene;
            return this;
        }

        public Builder group(GroupEnum group) {
            this.group = group;
            return this;
        }

        public Builder direction(DirectionEnum direction) {
            this.direction = direction;
            return this;
        }

        public Builder speed(double speed) {
            this.speed = speed;
            return this;
        }

        private Map<String, Image> imageMap() {
            if (this.group == GroupEnum.GREEN) {
                return Map.of(
                        DirectionEnum.UP.name(), new Image("/tank-green-up.png"),
                        DirectionEnum.DOWN.name(), new Image("/tank-green-down.png"),
                        DirectionEnum.LEFT.name(), new Image("/tank-green-left.png"),
                        DirectionEnum.RIGHT.name(), new Image("/tank-green-right.png")
                );
            } else {
                return Map.of(
                        DirectionEnum.UP.name(), new Image("/tank-red-up.png"),
                        DirectionEnum.DOWN.name(), new Image("/tank-red-down.png"),
                        DirectionEnum.LEFT.name(), new Image("/tank-red-left.png"),
                        DirectionEnum.RIGHT.name(), new Image("/tank-red-right.png")
                );
            }
        }

        public Tank build() {
            return new Tank(this);
        }
    }

    public static Builder builder() {
        return new Builder();
    }
}
