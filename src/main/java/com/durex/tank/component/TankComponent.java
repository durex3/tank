package com.durex.tank.component;

import com.almasb.fxgl.entity.component.Component;
import com.durex.tank.config.GameConfig;

public class TankComponent extends Component {

    private boolean isMove = false;
    private double distance;

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
        entity.setRotation(0);
        entity.translate(0, -distance);
    }

    public void moveDown() {
        if (isMove) {
            return;
        }
        isMove = true;
        entity.setRotation(180);
        entity.translate(0, distance);
    }

    public void moveLeft() {
        if (isMove) {
            return;
        }
        isMove = true;
        entity.setRotation(-90);
        entity.translate(-distance, 0);
    }

    public void moveRight() {
        if (isMove) {
            return;
        }
        isMove = true;
        entity.setRotation(90);
        entity.translate(distance, 0);
    }

    public void shoot() {

    }
}
