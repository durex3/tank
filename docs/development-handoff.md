# 开发交接（2026-10-15）


当前基线：功能实现与桌面记录至094（2026-10-15）；本机Godot 4.7.2执行`node tools/check.mjs`，30/30 PASS。Android触控、安全区、热稳定与真机导出未验收。

32项目录中，4炮塔（主战炮、速射机炮、短管散射炮、泡泡炮）及3底盘（轻型履带、重型履带、侦察轮式）就绪，共12种基础组合；其余25项可浏览设计，不可应用或试炼。已实现成长、金币解锁/升级、载重、草稿/撤销/应用、可恢复存档、四种普攻、四种炮塔大招与三种底盘被动。训练无正式奖励。

真实模型以`presentation/parts/proportion_v1`为基础；机炮与侦察底盘当前映射`presentation/parts/feedback_v1`；机库默认展示模型并支持拖动旋转，未就绪设计回退静态且不可旋转。七张卡片现为`assets/derived/model-reference-cards-v1`模型生成参考图的透明派生插画；原素材保留。炮管后坐、轮组/履带动态已接入；080统一尺寸、081圆形轮组比例修复、082材质与柔光、083头顶信息间距为当前表现基线。

## 启动与检查

先读AGENTS.md、架构规则、代码规范、开发计划及本次相关功能记录。Godot 4.7.2 Compatibility打开project.godot并F5。Windows锁定路径为上两级console.exe；其他路径使用GODOT_BIN覆盖。macOS示例：`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs`。

本机最新检查30/30 PASS；报告和截图位于忽略的artifacts，需本机重建。检查隔离存档到artifacts/host-data；用户个人存档不随Git同步，不得覆盖。

## 当前能力与操作

WASD/方向键移动、鼠标瞄准；主炮/散射/泡泡松手开火，机炮按住连射。触控左移动右瞄准，技能用Q或右下按钮；补能只补能，不刷新480tick最短技能间隔。暂停/失焦冻结模拟和反馈，恢复必须显式继续。模拟60Hz。

|部件|当前能力要点|
|---|---|
|轻型履带|实际自主速度达基础50%持续90tick后×1.25；停止/受阻12tick清除|
|重型履带|静止36tick展开，正面±60°直击减伤30%；移动意图解除，不防范围伤害|
|侦察轮式|合法非致死受击后下一tick自主移速×1.25持续90tick；原烟区150tick、敌方速度×0.65、冷却600tick，不刷新|
|主战炮|27tick蓄力、移速×0.6；16米、最多三目标240/144/86伤害，墙阻挡|
|速射机炮|180tick强化，每3tick普攻，单发为当前普攻60%；结束90tick红温禁火|
|短管散射炮|15tick准备；70°/4.5米、150伤害，墙遮挡；存活坦克和训练靶下一tick受击退|
|泡泡炮|普攻55基础伤害、39tick、4发，最后一发起84tick填弹；大招21tick准备，前方冻结部署点横排5泡、180tick留场、35伤害/泡、单敌方实体最多2泡|

参数以Resource及统一解析结果为准；详见054—058和运行定义。能量100，正式初始0，训练初始100；正式能量排除技能伤害和旧生命攻击。超重1降速20%，超重2起禁止应用/训练；已应用组合升级后非法则整笔拒绝。300金币仅首轮补给，无训练奖励。

## 当前入口与限制

- 领域：battle/、loadout/、definitions/；会话：session/；成长/持久化：content/growth/、profile/。
- 模型映射：presentation/tank_part_catalog.gd；卡片：hangar_part_art_catalog.gd；机械动态与特效仅消费提交状态/事件。
- 最新美术契约：068、080/081及086—088增补；原模型与卡片保留，不改变权威Muzzle/TurretSocket或碰撞。
- 1v1计时规则验证和普通对练已实现；团队Bot、完整3v3、联机未完成。Bot不自动决策大招。
- Android、真人平衡与连续观感仍需验收。桌面回归和历史截图不能替代真机。

## 本轮新增与下一批

084同步历史文档；085四类普攻/四大招反馈已实现并按真实会话拍摄，生成纹理/来源见assets/generated/vfx/weapon-identity-v1。

086：所有炮塔可视出膛在8tick内衔接原权威弹道，机炮双管成功提交后交替、独立后坐；拒绝/重复不换边。087：TankMotor限制车身转速4.8rad/s，仍为俯视方向移动，炮塔aim独立/挂接不滑动；正面装甲使用同一朝向。侦察轮组半径0.31米、校正源几何圆度、前轮转向；原模型保留。088：七张立体卡片离线重渲染，摄影配置content/presentation/part_cards.tres，运行时无额外摄影灯光。

最终29/29检查通过；出膛/转向14帧、机库两页/后排/详情已审阅。首次专项基准失败及修正见086/085，不隐去历史失败。Android与用户连续观感待验。下一独立记录090，先连续试玩这批反馈，再推进Android门槛；完整3v3和新部件后置。

089补充：用户确认继续WASD屏幕方向移动、鼠标独立瞄准，仅修正180°反向绕转。turn_preference由输入层注入并校验，非边界最短路不变。两组12张实际转弯截图及新增边界回归已通过，最终30/30 PASS；下一独立记录090。

## 历史交接（只读参考，已被以上现状替代）

以下保留053时期交接及当时网络失败记录；旧编号、参数、模型路径和“尚未推送”仅描述当时状态，不作为当前事实。

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

本次实际同步结果：实现提交3947792已创建，git push origin main失败：当前终端无法读取GitHub HTTPS用户名（could not read Username / Device not configured）。尚未推送。可在已登录GitHub的终端运行git push origin main；或携带artifacts/tank-handoff.bundle至家中，使用git clone tank-handoff.bundle tank-home恢复完整仓库历史。bundle不含个人存档/截图/缓存。


090—091补充（2026-10-15）：用户否决旧卡片观感后，新增转向制动/朝向速度衔接及七件卡片侧面/底座明暗重渲染；新增转向边界回归，完整30项通过。实际机库两页、后排、详情、升级与左右转向连续帧已审阅。参考图的轮廓饱满度和卡片占位仍有差距，真人手感/用户观感及Android待验收；下一独立编号095。


092卡片优化：图片区70→100px、显示画布收紧、低俯角重渲染七件模型。实际炮塔/底盘页、后排和升级窗口已审阅；720p第二排需要滚动，用户观感和Android待验收。下一编号095。


093：按用户实际截图回调卡片高度至138px、图片区80px及主体留白；保留v3取景。实际机库已审阅，用户观感/Android待验收，下一编号095。


094当前卡片：四炮塔与三底盘使用模型生成参考原图的透明派生插画，统一512×512、等比适配与居中。来源/提示词记录assets/generated/model-reference-cards-v1/provenance.json。主炮/轻履带由整车参考拆出，其余五件从独立参考图去背景；保留093卡片尺寸。实际机库两页/后排/详情/升级审阅及30/30检查通过，用户观感/Android待验收，下一编号095。
