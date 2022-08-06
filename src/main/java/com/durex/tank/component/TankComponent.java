package com.durex.tank.component;

import com.almasb.fxgl.core.util.LazyValue;
import com.almasb.fxgl.dsl.FXGL;
import com.almasb.fxgl.entity.Entity;
import com.almasb.fxgl.entity.EntityGroup;
import com.almasb.fxgl.entity.SpawnData;
import com.almasb.fxgl.entity.component.Component;
import com.almasb.fxgl.time.LocalTimer;
import com.durex.tank.config.GameConfig;
import com.durex.tank.enums.DirectVector;
import com.durex.tank.enums.GameType;

import java.util.List;

public class TankComponent extends Component {

    private boolean isMove = false;
    private double distance;
    private DirectVector direct = DirectVector.UP;
    private LocalTimer timer;

    @Override
    public void onAdded() {
        timer = FXGL.newLocalTimer();
    }

    /**
     * 可碰撞的实体集合
     */
    private final LazyValue<EntityGroup> collidingEntityGroup = new LazyValue<>(() ->
            FXGL.getGameWorld().getGroup(
                    GameType.BORDER,
                    GameType.BRICK,
                    GameType.SEA,
                    GameType.STONE,
                    GameType.PLAYER,
                    GameType.ENEMY
            )
    );

    /**
     * <h2>每一帧都会刷新</h2>
     *
     * @param tpf 耗时
     */
    @Override
    public void onUpdate(double tpf) {
        isMove = false;
        distance = GameConfig.TANK_MOVE_SPEED * tpf;
    }

    public void moveUp() {
        if (isMove) {
            return;
        }
        isMove = true;
        direct = DirectVector.UP;
        entity.setRotation(0);
        move();
    }

    public void moveDown() {
        if (isMove) {
            return;
        }
        isMove = true;
        direct = DirectVector.DOWN;
        entity.setRotation(180);
        move();
    }

    public void moveLeft() {
        if (isMove) {
            return;
        }
        isMove = true;
        direct = DirectVector.LEFT;
        entity.setRotation(-90);
        move();
    }

    public void moveRight() {
        if (isMove) {
            return;
        }
        isMove = true;
        direct = DirectVector.RIGHT;
        entity.setRotation(90);
        move();
    }

    public void shoot() {
        if (timer.elapsed(GameConfig.SHOOT_DELAY)) {
            final SpawnData data = new SpawnData(
                    entity.getCenter().subtract(8.0 / 2, 10.0 / 2)
            );
            data.put(GameConfig.DIRECT, direct.getVector());
            data.put(GameConfig.OWNER_TYPE, entity.getType());
            data.put(GameConfig.LEVEL, entity.getComponent(TankLevelComponent.class).getValue());
            FXGL.spawn(GameConfig.BULLET, data);
            timer.capture();
        }
    }

    private void move() {
        int len = (int) distance;
        for (int i = len; i > 0; i--) {
            entity.translate(direct.getVector());
            if (isColliding()) {
                entity.translate(direct.getVector().multiply(-1));
                return;
            }
        }
    }

    public boolean isColliding() {
        boolean isColliding = false;
        List<Entity> entityList = collidingEntityGroup.get().getEntitiesCopy();
        entityList.remove(entity);
        for (Entity e : entityList) {
            if (entity.isColliding(e)) {
                isColliding = true;
                break;
            }
        }
        return isColliding;
    }

    public DirectVector getDirect() {
        return direct;
    }
}
