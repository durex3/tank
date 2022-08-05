package com.durex.tank.enums;

import javafx.geometry.Point2D;

public enum DirectVector {

    UP(new Point2D(0, -1)),
    DOWN(new Point2D(0, 1)),
    LEFT(new Point2D(-1, 0)),
    RIGHT(new Point2D(1, 0)),
    ;

    private final Point2D vector;

    DirectVector(Point2D vector) {
        this.vector = vector;
    }

    public Point2D getVector() {
        return vector;
    }
}
