package com.durex.tank.component;

import com.almasb.fxgl.dsl.components.RechargeableIntComponent;
import com.durex.tank.config.GameConfig;

public class TankLevelComponent extends RechargeableIntComponent {

    public TankLevelComponent() {
        super(GameConfig.TANK_MAX_LEVEL);
    }

    public void upgrade() {
        this.restore(1);
    }

    public void downgrade() {
        this.damage(1);
    }

    public void upgradeFull() {
        restoreFully();
    }
}
