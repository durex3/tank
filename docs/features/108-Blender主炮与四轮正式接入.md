# 108 Blender主炮与四轮正式接入

2026-10-16。状态：正式接入及桌面验收通过；Android与用户观感待验收。

## 目标、所属层与接口

把用户认可的105 Blender主炮与四轮接入正式机库/训练，而不继续停留在106专用预览。使用godot-nodes-scenes技能。改动属于presentation、表现Resource、离线工具和接入测试；MovementSession只补读取阴影Resource参数，不改战斗行为。

正式目录presentation/parts/mechanical_v1，稳定ID不变。根identity、Muzzle=(0,.02,-1.05)、TurretSocket=(0,.76,0)保持不变；主炮Geometry偏移.125保留105/106装配高度。可视炮口/后坐与完整轮组仍由既有提交事件/状态驱动；不改WASD屏幕方向或鼠标独立瞄准，不改拥有/金币/成长/存档。

## 统一外廓与来源

原105 GLB、blend、图片只读保留。主炮保留原几何8588三角面。四轮保留原28884三角面、轮胎/轮盖及轴心；192块胎纹的倾斜先于绕轴旋转，使各径向一致，另存assets/derived/mechanical-production-v1/scout_wheels.glb及provenance.json。

part_size.tres统一迁移：炮塔位置(-.519,.125,-1.16)、尺寸(1.038,.594,1.708)；底盘位置(-.852,-.002,-.952)、尺寸(1.704,.911,1.904)。0.0002米门槛未放宽。

其余三个旧炮塔壳体等比缩放，独立侧装甲补齐共同宽度，炮管前移及套筒沿轴延长适配总长，不非等比压圆截面、不添加高白柱。旧轻/重履带仅静态车壳调整高度，独立轮组刚性、履带路径适配。它们是过渡适配，不等于用户期待的剩余Blender重制作品；新造型仍须逐件制作。

## 文件与重建

- tools/prepare_mechanical_108.py：Blender从105四轮GLB导入，仅修正胎纹顺序，派生另存。
- tools/integrate_mechanical_108.gd：从固定105/103源派生七场景，接口/尺寸检查，写统一Resource，不从当前Catalog累积缩放。
- presentation/tank_part_catalog.gd：七件正式映射；presentation/hangar_part_art_catalog.gd及assets/derived/mechanical-cards-v1：七张512透明实际模型卡片。
- tools/capture_mechanical_cards_108.gd、capture_mechanical_108.gd：卡片、十二组合正背、真实机库旋转/缩放截图；使用独立fixture存档。
- tools/play_mechanical_108.gd：直接走正式Catalog的真实训练入口，未安装临时样板适配器，80tick自动移动/开火实拍。
- training_view/hangar_preview资源及style、MovementSession/HangarPreview：法线偏移1.0、深度偏移0.3读取Resource，保留实时阴影；显著减轻原normal_bias=0时地面/箱体的高对比条纹；浅色斜纹仍可见，不宣称阴影彻底修复。
- tests/presentation/tank_parts_tests.gd：纹理材质隔离测试显式选择仍有贴图的autocannon；不再假定默认新主炮必须使用旧贴图清理shader。
- AGENTS、架构规则、080契约、制作手册、开发计划、功能索引同步。

## 实际失败与修正

1. 首次Godot导入尚未结束就运行只读检查，缺少导入缓存；停止检查并等待完整导入后重跑。
2. 首轮派生机炮Geometry偏移重复扣除、履带宽度相差.012米，尺寸断言失败；修正原Geometry位移换算和履带实际宽度后七件通过。
3. 首轮完整check有轮胎圆度失败及旧默认炮塔Body材质测试失败。定位到105胎纹欧拉旋转顺序和新主炮纯色PBR；分别修模型与显式贴图测试fixture，未放宽圆度断言。
4. Blender派生脚本首跑括号语法错误，后续修正；一次因导入对象仍为QUATERNION模式导致Euler赋值不生效，显式XYZ后重新导出并通过真实轮组测试。
5. 沙箱Godot日志/系统证书访问失败，最终验证改正常权限执行；未屏蔽错误。
6. Blender MCP工具已加载，调用path_info实际返回localhost:9876无法连接，本轮通过本机Blender 5.2.2 CLI完成，不能声称MCP已连通。

## 验收

- Blender CLI派生成功；Godot完整导入成功。
- integrate_mechanical_108.gd：七件外廓通过。
- firearm_handling_tests.gd：PASS，包括真实轮径、轴心、前轮转向、双管交替、独立射口及暂停。
- `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs`：30/30 PASS，报告artifacts/check-report.json。
- capture_mechanical_cards_108.gd：七张512透明卡片生成成功，来源记录另存。
- capture_mechanical_108.gd：十二组合正背、1280×720机库与960×640缩放截图通过并已审阅；证据artifacts/108-twelve-combinations.png、108-twelve-rear.png、108-hangar.png、108-hangar-rear.png、108-hangar-small.png。
- play_mechanical_108.gd -- --capture：80tick提交移动/开火、轮组和后坐、固定权威射口PASS；已审阅03/30/80连续过程关键帧，证据artifacts/108-training-*.png。
- 自动导入改写的七份无关旧资源.import元数据已恢复，没有修改其原素材。
- 后续光影复查一次遇到窗口失焦暂停，使捕获末帧轮角回到初值而断言失败。捕获脚本改为每tick显式恢复、记录过程是否发生轮组运动；正式游戏失焦规则不变。深度偏移1.0未进一步消除浅纹，回退已通过完整检查的0.3。

Android触控、安全区、性能与热稳定仍待真机；剩余五件美术重制及用户连续试玩未完成。桌面通过不代表M0/M1真机出口或M3整体交付。
