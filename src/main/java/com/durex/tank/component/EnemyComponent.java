package com.durex.tank.component;

import com.almasb.fxgl.core.math.FXGLMath;
import com.almasb.fxgl.entity.component.Component;
import com.durex.tank.enums.DirectVector;

public class EnemyComponent extends Component {

    @Override
    public void onUpdate(double tpf) {
        TankComponent component = entity.getComponent(TankComponent.class);
        DirectVector direct = component.getDirect();
        if (FXGLMath.randomBoolean(0.025)) {
            direct = FXGLMath.random(DirectVector.values()).orElse(DirectVector.UP);
        }
        switch (direct) {
            case UP -> component.moveUp();
            case DOWN -> component.moveDown();
            case LEFT -> component.moveLeft();
            case RIGHT -> component.moveRight();
        }
        if (FXGLMath.randomBoolean(0.03) || component.isColliding()) {
            component.shoot();
        }
    }
}
