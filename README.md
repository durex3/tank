# Tank Arena

Godot 4.7.2横屏手机3v3坦克项目。当前支持三种炮塔×三种底盘的基础移动、普通攻击和训练配装，已支持独立1v1离线单局规则验证；完整3v3对局尚未实现。

## 开发入口
每次开发先读[AGENTS.md](AGENTS.md)、[架构规则](docs/rules/architecture.md)、[代码规范](docs/rules/code-style.md)与[开发计划](docs/development-plan.md)。每项功能记录在[功能索引](docs/features/README.md)，按NNN-功能名称.md递增。原始架构与用户assets保留。

## 运行与操作
Godot 4.7.2打开project.godot，F5运行。首页Drive & fire进入默认主炮/轻履带训练；Open modular hangar进入机库，选择中文炮塔/底盘卡片后点“进入试炼场”进入对应训练，Back返回机库并恢复本次选择。选择只改变草稿，应用改装才写入存档，撤销恢复当前装备。基础部件支持解锁和升级。

WASD/方向键移动，鼠标瞄准。主炮和散射炮松开鼠标左键或空格发射；机关炮按住连射，松手停止。Touch controls切换触控：左摇杆移动，右摇杆瞄准；主炮/散射松手开火，机关炮拖出死区后按住连射。Esc或Pause暂停；失焦后需显式继续。桌面鼠标只能模拟单指，不能替代Android多指验收。

训练靶耐久350/670/1445，中央靶往返，击毁后三秒重建。主炮120伤害/48tick；机关炮25伤害/10tick；散射每颗32伤害、5颗、24度扇形/60tick。物理60Hz，机关炮配置0.16秒对应实际约0.167秒。训练无正式奖励，技能与底盘被动尚未执行，正式比赛后续开发。

点击Start sparring开启离线对练：对手在中央通道巡逻，视线无遮挡且进入射程时开火。双方可受伤，死亡后三秒在安全位置重建；重建后一秒保护期内不能受伤或开火，暂停冻结计时。玩家死亡会清除旧操作，重建后需重新输入。

点击Start timed duel · 1v1开始全新计时对局，沿用当前配装。4分钟或先到20分结束，平分进入最多30秒加时；加时领先胜，无有效分差则平局。结算显示双方击杀/死亡/实际伤害；Rematch创建新局，Back返回进入训练前的首页或机库。此双车规则验证不发金币/经验，练靶与普通对练仍不计分。

## 检查与证据
根目录执行node tools/check.mjs，需要Node.js；Godot默认使用上两级console.exe，其他机器用GODOT_BIN指定。报告artifacts/check-report.json；运行数据隔离到artifacts/host-data，产物不入版本控制。当前21项检查覆盖架构、版本、导入、领域、输入、移动、战斗、暂停生命周期、贴图、部件机库、武器变体与配装训练、离线对练、单局规则与结算重开、机库美术、镜头与战斗视觉、启动。

Godot执行tools/capture_weapon_variants.gd可生成artifacts/training-scatter.png及training-autocannon.png；tools/capture_hangar.gd生成机库三组截图。tools/capture_sparring.gd生成对练受伤、倒地、重建截图。tools/capture_match.gd生成运行、真实结算、重开及加时截图；加时截图使用2秒测试规则副本。桌面截图和headless不替代Android触控、性能、安全区与导出验收。

## 美术与范围
炮口、命中、爆炸贴图已接入；六个独立底盘/炮塔基础视觉场景在presentation/parts，可按[部件接口](docs/art/009-部件接口约定.md)替换。六个部件已完成独立白瓷/金色风格化3D首轮制作，地图保留原碰撞布局并增加地砖和饰面；尚未达到最终精细美术品质；[美术规范](docs/art/美术接入规范.md)记录导入、来源与表现边界。

待完成技能/被动、完整3v3赛制、团队Bot及全地图导航、音效与联机。Android SDK/JDK、导出、安全区、后台和真机验收仍待完成，不宣称里程碑出口通过。

中文机库已接入九种配装设定图，复用六张现有图并补齐三张轮式图；可切换基础装配模型。图片并非战斗3D模型，战斗已接入独立3D部件与近景跟随镜头，仍需后续美术与移动端优化。详见[013功能记录](docs/features/013-已有坦克美术接入与中文机库.md)与[类型设计](docs/炮塔与底盘类型设计.md)。

014记录见[模块化战斗模型与近景镜头](docs/features/014-模块化战斗模型与近景镜头.md)。按用户要求，后续先做完炮塔/底盘基础系统与完整机库，再扩展实战。

## 公司继续开发

先读[开发交接](docs/development-handoff.md)：当前完成至025，下一步实现3种底盘被动与3种炮塔大招，相关功能尚未实现。新机器设置GODOT_BIN后运行node tools/check.mjs。
