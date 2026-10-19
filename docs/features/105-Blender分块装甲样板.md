# 105 Blender分块装甲样板

2026-10-16。独立样板制作及技术检查完成；正式游戏接入、用户观感和Android验收待完成。用户要求借鉴MiniTanks做法，直接用Blender制作一套炮塔与底盘，并授权无需确认完成。

## 目标与所属层

离线美术制作：以斜面装甲、局部倒角、低转环、白灰黄材质制作原创主炮和四轮底盘。MiniTanks资源仅只读检视，没有复制其网格或纹理。无法从导出资源判断对方使用的建模软件，本样板不声称复现其完整生产流程。

## 模型与接口

- `assets/derived/mechanical-sample-v1/cannon.glb`：8588三角面；主炮、独立RecoilPivot与VisualMuzzle。
- `assets/derived/mechanical-sample-v1/scout_wheels.glb`：28884三角面；WheelLeftFront/Rear、WheelRightFront/Rear四个独立轴心，白平轮盖、黄轮圈、黑横槽。
- `source_art/mechanical-sample-v1/mechanical_sample.blend`：可编辑源文件、完整分件、材质、摄影和灯光。
- `tools/build_mechanical_sample_105.py`：可重建的Blender脚本，另建场景，原资源保留。
- `tools/preview_mechanical_sample_105.gd`：独立Godot预览，验证轮组与炮管节点，保存正背面截图。

本样板是造型研究，外廓不宣称满足080正式尺寸契约。炮塔约1.038×0.594×1.708米，底盘约1.704×0.911×1.919米；预览炮塔偏移0.885米仅用于样板展示。正式目录、part_size.tres、权威挂点与游戏逻辑没有改动。后续接入应统一设计所有部件外廓，禁止为补齐高度重新加白色增高柱。导出坐标Blender+Y前向，映射Godot-Z前向。

## 验收及实际结果

1. Blender MCP执行失败：127.0.0.1:9876连接不可用。改用本机`D:/soft/Blender 5.2/blender.exe --background --factory-startup --python tools/build_mechanical_sample_105.py`，成功导出并渲染；日志`artifacts/105-build.log`。
2. 初版胎纹面数较高，改用一段倒角，底盘从56532降至28884；补黑色炮口内衬。每个网格边检查无非流形边，报告`assets/derived/mechanical-sample-v1/report.json`。该检查不证明所有相交面均无穿插；连接件有设计上的嵌合。
3. `node tools/check.mjs`：通过，日志`artifacts/check-report.json`。未修改战斗行为，未新增领域回归。
4. 独立预览初次断言误把Wheel开头的轮盖细节当作轮组，已改为四个明确轴心名称；重跑`--script tools/preview_mechanical_sample_105.gd`成功，输出`MECHANICAL SAMPLE IMPORT AND RIG NODES: PASS`。日志`artifacts/105-godot.log`。
5. 已审阅Blender正面、背面及Godot正背面。产物`front.png`、`rear.png`、`side.png`、`godot-front.png`、`godot-rear.png`均为真实模型渲染，不是生成参考图。

## 限制与下一步

未接正式机库或战斗；未验证完整动画、统一尺寸契约与Android性能。材质采用纯色PBR，无烘焙纹理；多对象分件便于编辑，正式交付需在保留运动轴心后按材质合并静态结构降低绘制调用。当前Godot预览光照简化，不能代表最终游戏材质效果。
