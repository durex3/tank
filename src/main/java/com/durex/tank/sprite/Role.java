package com.durex.tank.sprite;

import com.durex.tank.enums.DirectionEnum;
import com.durex.tank.enums.GroupEnum;
import com.durex.tank.scene.GameScene;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.image.Image;

import java.util.Map;

public abstract class Role extends Sprite {

    private boolean live;
    private final GroupEnum group;
    private DirectionEnum direction;
    private Double speed;
    private final Map<String, Image> imageMap;

    public Role(Map<String, Image> imageMap, Double x, Double y, Double width, Double height, GroupEnum group, DirectionEnum direction, double speed, GameScene gameScene) {
        super(null, x, y, width, height, gameScene);
        this.group = group;
        this.direction = direction;
        this.speed = speed;
        this.imageMap = imageMap;
    }

    public abstract void move();

    public abstract boolean isCollision(Sprite sprite);

    /**
     * <h2>销毁</h2>
     */
    public abstract void destroy();


    @Override
    public void paint(GraphicsContext graphicsContext) {
        Image image = imageMap.get(direction.name());
        graphicsContext.drawImage(image, this.getX(), this.getY(), this.getWidth(), this.getHeight());
    }

    public boolean isLive() {
        return live;
    }

    public void setLive(boolean live) {
        this.live = live;
    }

    public DirectionEnum getDirection() {
        return direction;
    }

    public void setDirection(DirectionEnum direction) {
        this.direction = direction;
    }

    public Double getSpeed() {
        return speed;
    }

    public void setSpeed(Double speed) {
        this.speed = speed;
    }

    public GroupEnum getGroup() {
        return group;
    }

    public Map<String, Image> getImageMap() {
        return imageMap;
    }
}
