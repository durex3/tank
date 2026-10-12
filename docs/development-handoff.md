# 开发交接（2026-10-12 晚间续开发）

## 当前版本

实现至053，下一独立功能编号054。当前批次041—053包含六能力设计/实现、训练场清晰度与界面、技能特效及独立部件展示比例修复。历史过程和失败记录查对应功能文档，不使用旧交接中的033能力提案。

32项部件目录可浏览；已有三炮塔×三底盘支持成长、载重、草稿/撤销/应用、持久化、普通攻击及六能力训练。其他26项部件不代表实战已实现，轮到开发时重新设计能力。九种组合不代表完整3v3已完成。

现有模型映射presentation/parts/card_finished，用户已确认本轮模型作为收尾版。静态整车使用同源部件图拼装，真实3D入口独立；053只归一化卡片/升级窗口展示，未改变整车比例。PNG不是3D。

## 今晚启动步骤

1. 使用Godot 4.7.2 Compatibility打开project.godot；仓库origin为https://github.com/durex3/tank.git。
2. 先读AGENTS.md、docs/rules/architecture.md、docs/rules/code-style.md、docs/development-plan.md及相关功能记录。
3. 设置本机Godot路径再运行检查；toolchain.lock的默认路径为Windows，macOS不能直接使用该默认路径。
4. F5进入机库。新机器个人存档不会随Git同步，首轮补给300金币；不要将测试存档当正式数据。选择已就绪配装进入试炼。
5. 试炼用Q或右下技能按钮释放；训练补能按钮只补能，不刷新8秒最短释放间隔。暂停/失焦冻结模拟，恢复须显式继续。

macOS验收命令：

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs
```

Windows PowerShell示例（替换本机路径）：

```powershell
$env:GODOT_BIN = 'C:\Tools\Godot_v4.7.2-stable_win64_console.exe'
node tools/check.mjs
```

## 六能力当前行为

最终参数由definitions/basic_ability_rules.gd及content/rules/basic_abilities.tres提供，设计依据docs/design/041-基础六能力重设计.md；本表帮助定位，不另建数值实现。

|部件|能力|当前关键行为|
|---|---|---|
|轻型履带|巡航推进|实际自主移动达基础速度50%，持续90tick后速度×1.25；停止/受阻12tick清除|
|重型履带|迎击装甲|静止36tick展开，正面±60°直击减伤30%；移动意图立即解除，不防范围伤害|
|侦察轮式|脱险烟幕|非致命敌方受伤后向后释放烟区，半径1.6m、150tick、敌方速度×0.65、冷却600tick；不隐身|
|主战炮|破阵重炮|27tick蓄力、移速×0.6，射程16m，最多三目标240/144/86伤害，墙体阻挡|
|速射机炮|火力风暴|180tick强化，按住普攻每5tick射击，松手停火；结束后36tick散热|
|短管散射炮|震荡清场|15tick准备，锁定方向，前方70°/4.5m造成150伤害，存活坦克击退1.2m；墙遮挡|

模拟60Hz；能量100、成功释放扣满，最短间隔480tick。正式初始0、每tick恢复0.05，并按普通有效伤害充能，技能伤害不充能；训练初始100。技能数值不擅自跟随普通攻击成长。载重超重1降速20%，超重2起禁止应用/训练。

## 验收及已知限制

053最新完整tools/check.mjs：23/23 PASS，git diff --check PASS。已审阅六能力及真实格挡/弹丸飞行/散热共9张实拍，机库炮塔/底盘页及升级窗口实际渲染。首次未指定GODOT_BIN时ENOENT失败已记入053，改路径后通过。

训练靶使用真实模型外观，但仍保留原训练靶碰撞及350/670/1445血量。震荡击退需用“开始对练”的真实TankActor测试，静态伤害靶不作为击退验证。Bot目前普通攻击，不自动决策大招。

截图和check-report在忽略的artifacts/，不随提交同步；可重新生成：

```sh
Godot --path . --script tools/capture_abilities.gd
Godot --path . --script tools/capture_training_redesign.gd
Godot --path . --script tools/capture_hangar_workbench.gd
```

上述Godot替换为本机可执行文件。美术贴图及提示词/来源已在assets/generated/vfx/abilities-v1提交范围内；原素材只读。

Android触控、安全区、字体、透明过绘制、热稳定及真机导出未验收。桌面规则回归不证明玩法平衡；技能音效、镜头震动、模型后坐尚未增加。M0/M1出口仍有真机门槛，不能宣称M3整体交付。

## 下一步优先事项

先连续试玩九种组合，记录触发是否直观、能量循环、烟区减速、装甲正侧面差异及震荡击退；关注火力风暴散热提示是否足够。以试玩证据决定调参或反馈改动，不继续无依据叠特效。随后做Android真机验收；其他部件/3v3后置。新功能用054开始，新增记录并同步计划和索引。

## 代码入口

- battle/abilities/：独立能力状态、底盘被动及震荡策略；battle/battle_simulation.gd负责固定tick提交顺序。
- session/movement_session.gd、sparring_session.gd：会话调度、训练补能、生命周期。
- input/desktop_input_source.gd、touch_input_source.gd：命令采样，UI不直接执行业务。
- presentation/ability_effects.gd、ability_sprite_effects.gd、shaders/shock_sector.gdshader：提交事件驱动特效；definitions/ability_effect_style.gd配置表现预算。
- presentation/training_view_style.gd、arena_dressing.gd、ui/widgets/training_hud.gd、training_touch_overlay.gd：训练画面与HUD。
- presentation/hangar_part_art_catalog.gd：texture用于拼装源图，display_texture用于单独展示，勿混用。
- tests/battle/ability_tests.gd、tests/presentation/ability_vfx_tests.gd、tools/check.mjs：规则/反馈回归。
- profile/、content/growth/：成长及持久化；没有训练收益或个人存档提交。

## 提交与跨机器同步

本次按用户要求提交041—053全部现有实现及文档。不提交.godot、artifacts、个人存档、密钥、构建包。Git提交与远程推送是独立步骤；本交接不将本地提交冒充已推送。回家从远端获取前，确认本次提交已同步；网络失败时保留本地提交，禁止强推覆盖远端历史。
