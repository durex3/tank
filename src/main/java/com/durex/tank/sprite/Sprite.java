package com.durex.tank.sprite;

import com.durex.tank.scene.GameScene;
import javafx.geometry.Rectangle2D;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.image.Image;

public abstract class Sprite {

    private final Image image;
    private Double x;
    private Double y;
    private final Double width;
    private final Double height;
    private GameScene gameScene;


    public Sprite(Image image, Double x, Double y, Double width, Double height) {
        this.image = image;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    public Sprite(Image image, Double x, Double y, Double width, Double height, GameScene gameScene) {
        this.image = image;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.gameScene = gameScene;
    }

    /**
     * <h2>销毁</h2>
     */
    public abstract void destroy();

    /**
     * <h2>绘制</h2>
     *
     * @param graphicsContext 画笔
     */
    public void paint(GraphicsContext graphicsContext) {
        graphicsContext.drawImage(image, x, y, width, height);
    }

    public Rectangle2D getRectangle2D() {
        return new Rectangle2D(x, y, width, height);
    }

    public Double getX() {
        return x;
    }

    public void setX(Double x) {
        this.x = x;
    }

    public Double getY() {
        return y;
    }

    public void setY(Double y) {
        this.y = y;
    }

    public GameScene getGameScene() {
        return gameScene;
    }
}
