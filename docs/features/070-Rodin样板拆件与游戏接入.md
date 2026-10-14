# 070 Rodin样板拆件与游戏接入

日期：2026-10-14。状态：已接入，桌面自动检查与截图复核通过；Android及连续真人观感待验收。

## 目标、所属层与接口

用户认可069样板并要求继续。下载原整车和BANG Basic拆件版，用于主战炮＋轻履带；保留其余部件及原资产。所属presentation、派生资源与session表现适配，不修改战斗规则、稳定ID或原权威挂点。

- BANG任务`a2b536e9-d910-40d5-b536-b811e0d575b4`，结果：https://hyper3d.ai/workspace/rodin/a2b536e9-d910-40d5-b536-b811e0d575b4
- 六网格映射：0车身，1/2左右履带，3炮塔壳体，4炮管，5炮口罩。炮管与罩归RecoilPivot，原UV、嵌入贴图、法线与几何不改写。
- 根identity、TurretSocket=(0,0.76,0)、Muzzle=(0,0.02,-1.05)不变。仅Visual节点校准前向-Z、比例与地面位置，炮塔转轴对齐原整车座圈。
- TankView.visual_muzzle_position提供独立VisualMuzzle；MovementSession给表现消费者复制事件，不改写提交事实。普通枪焰/破阵蓄力与发射用可视炮口；弹丸出生、轨迹、碰撞和伤害继续由原模拟控制。

## 变更文件

- assets/imported/rodin-v1/：两个GLB与来源/哈希清单。
- tools/derive_rodin_parts.py、assets/derived/rodin-v1/：可重建拆件包装与独立部件图。底盘20052、炮塔9948，整车30000三角形；三种嵌入贴图为颜色、法线和金属/粗糙度。
- presentation/parts/rodin_v1/、tank_part_catalog.gd：映射主战炮/轻履带；旧模型保留。
- presentation/hangar_part_art_catalog.gd：卡片使用对应新模型独立渲染图，不裁整车。
- content/presentation/hangar_preview.tres：取景2.5→2.9避免长炮管旋转裁边。
- presentation/tank_view.gd、ability_effects.gd、ability_sprite_effects.gd、session/movement_session.gd：可视炮口及只读事实适配。
- tools/capture_rodin_sample.gd、capture_rodin_icons.gd、capture_cannon_recoil.gd：四角度/卡片/开火截图；后者修复resume后重新启用自动物理造成手动命令序号冲突。
- tests/presentation/tank_motion_tests.gd：可视炮口随独立炮管移动、权威射口不变、提交事件不被表现适配改写。

## 实际执行与验收

- 网络沙箱首轮下载DNS失败，申请网络权限后两个GLB下载成功。
- BANG High被账户权限拒绝，Basic请求成功，状态completed。未声称开通高分辨率。
- `python3 tools/derive_rodin_parts.py`：PASS，30000三角形。原整车单网格、拆件版六网格均已核对。
- Godot4.7.2 headless导入：PASS。
- Godot执行capture_rodin_sample.gd及`-- --parts`：PASS，四角度截图；正背面已审阅，未发现大面积缺面或原位装配开缝。
- capture_rodin_icons.gd：PASS，透明512×512独立部件图。
- capture_imported_models.gd：PASS，十二组合、背面旋转、缩放和静态回退；混搭已审阅。首轮侧面炮管裁边已调整取景。
- capture_cannon_recoil.gd首轮命令断言失败；修复resume自动推进后PASS。后坐峰值与恢复、暂停检查通过，首轮发现旧位置枪焰后加入可视炮口，最终训练正常尺寸与开火峰值截图已审阅，枪焰位于新炮口；独立炮管恢复及暂停断言通过。
- 完整检查首轮25/25 PASS；最终`env GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs`：25/25 PASS；新增事件不变性回归单独重跑PASS；`git diff --check`：PASS。旋转裁边修复及更新卡片截图已审阅。

## 限制与下一步

可视炮口随长炮管，权威弹丸仍从原射口出生；此处刻意分离，不能称弹道改动或完全重合。履带为整组网格，未拆独立车轮，未实现轮组滚动。派生GLB保留源二进制和未引用网格以确保无损，存在重复纹理/无用缓冲，正式包需后续无损整理。只替换本次两个模块，其他部件仍旧风格。连续真人试玩、极限近景接缝、Android帧率/显存/热稳定待验收。
