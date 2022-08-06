package com.durex.tank.config;

import javafx.util.Duration;

public class GameConfig {


    private GameConfig() {
    }

    public static final int CELL_SIZE = 24;
    public static final String TITLE = "坦克大战";
    public static final String VERSION = "v1.0";
    public static final String PLAYER = "player";
    public static final String BRICK = "brick";
    public static final String GREENS = "greens";
    public static final String SEA = "sea";
    public static final String SNOW = "snow";
    public static final String STONE = "stone";
    public static final String BORDER = "border";
    public static final String FLAG = "flag";
    public static final String BULLET = "bullet";
    public static final String ENEMY = "enemy";
    public static final String EXPLODE = "explode";
    public static final String DIRECT = "direct";
    public static final String OWNER_TYPE = "ownerType";
    public static final String LEVEL = "level";

    public static final int TANK_MOVE_SPEED = 150;
    public static final int BULLET_SPEED = 400;

    public static final Duration SHOOT_DELAY = Duration.seconds(0.35);
    public static final Duration EXPLODE_TIME = Duration.seconds(0.35);

    public static final int PLAYER_MAX_HEALTH = 5;
    public static final int TANK_MAX_LEVEL= 2;
}
