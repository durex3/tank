# 109 Blender剩余五部件建模与接入

2026-10-16。状态：桌面自动检查与实际渲染验收通过，修订后用户观感与Android待验收。

## 目标与所属层

用户明确要求剩余三炮塔、两底盘按制作手册和已认可105/108流程制作。本轮通过已连通Blender MCP完成原创建模、分件、几何检查、导出、合批及Blender渲染；Godot接入复用既有表现系统。技能采用godot-nodes-scenes。没有Hyper3D任务、外部生图或复制MiniTanks网格。

## 造型与接口

- autocannon：白色斜面侧装甲、深灰低壳体、两根冷却套筒炮管及黄色圆口；RecoilPivot/Right、VisualMuzzle/Right独立。
- scatter：前伸厚楔形装甲、短粗十二边炮口、黄色边缘、真实深色内壁，保持单管。
- bubble_cannon：圆顶压力舱、独立悬空喷环、四根细支撑杆、青色圆形压力窗和顶部圆盖；无背部蓝罐、外置软管或背包。
- light_tracks：低宽斜面车壳、开放三轮侧面、薄护板、青色前灯/红尾灯和齐平散热后板。
- heavy_tracks：相同共同外廓，四轮履带、分段侧裙板和加强前保险杠；不因重型放大。

两底盘的车壳为新Blender几何，完整轮子、闭合带体和循环履带片继续复用已验证TrackRig，非声称轮带也重新建模。source_art中的runtime_tracks.glb为Godot运行轮带快照，只用于可编辑组合检查场景；生产不加载该快照。

新五件正式目录presentation/parts/mechanical_v2。主炮与四轮仍保留108 mechanical_v1。统一尺寸Resource没有变化；炮塔完整外廓1.038×.594×1.708米、底盘1.704×.911×1.904米。根identity、Muzzle=(0,.02,-1.05)、TurretSocket=(0,.76,0)保持不变，炮塔Geometry偏移.125。

普攻、技能、成长、拥有与存档、WASD/鼠标输入和权威伤害不变；后坐仅成功提交事件驱动，轮带仅消费提交位移，暂停/重建清理沿用现有系统。

## 文件及来源

- tools/build_mechanical_family_109.py：独立场景原创建模，复用105已确认配色及基本斜面/倒角方法，保存分件源GLB与几何统计。
- tools/finish_mechanical_family_109.py：保留可编辑源物体，只对导出副本按材质和运动父节点合批；禁止跨左右炮管合并。
- source_art/mechanical-family-v2：可编辑mechanical_family.blend、实际装配mechanical_family_review.blend与两履带检查快照。
- assets/derived/mechanical-family-v2：五份GLB、report.json、batches.json、provenance.json及Blender正背侧实拍。
- tools/integrate_mechanical_family_109.gd：从固定新GLB包装挂点，轮带参数复用固定108源，校验共同位置/外廓，不改变尺寸配置。
- tools/export_family_rigs_109.gd、render_mechanical_family_109.py：准确轮带快照及Blender组合检查。
- presentation/tank_part_catalog.gd：只替换五件映射；HangarPartArtCatalog与mechanical-cards-v2同步真实模型卡片。
- capture_mechanical_cards_109.gd、capture_mechanical_family_109.gd、capture_family_training_109.gd：卡片、十二混搭正背面/旋转缩放、三种新武器真实训练动作实拍。
- tank_parts_tests.gd：旧贴图shader隔离回归改用显式旧机炮fixture，不再假定新纯色Blender机炮存在贴图/Body名；测试语义保留。
- AGENTS、架构、计划、索引和制作手册同步。

## 几何与批次

|部件|三角面（新GLB）|导出Mesh数|原可编辑Mesh数|
|---|---:|---:|---:|
|机炮|8824|15|36|
|散射炮|5600|9|23|
|泡泡炮|7396|10|22|
|轻履带车壳|9344|7|40|
|重履带车壳|12752|7|52|

两车壳面数不含运行生成的轮带。建模检查各独立网格无非流形边，不代表所有装配交叠都被排除；连接件保留设计嵌合，实际正背面另行审阅。Android绘制调用与性能仍待真机。

## 实际验收与迭代

- Blender MCP实际生成五件成功，GLB及可编辑blend已保存；源模型几何报告完成。
- 初轮Godot五件包装全部通过统一外廓，未放宽0.0002米门槛。
- 首轮近景发现侧槽口、后通风槽及泡泡/散射炮口黄边共面闪烁；装甲轻微内收、后板收薄、白炮口止于黄圈之前，重新导出并复查Blender正背面通过。
- 合批初次对单对象组调用join产生“No mesh data to join”提示，输出仍成功；重建脚本改为仅多对象组合并，最终合批执行无该提示。
- Blender正背侧三组合已渲染并审阅，原105/108资源未覆盖。
- 用户指出泡泡炮与短管轮廓过于接近，已将泡泡炮楔形壳与实心短喷管改为圆顶压力舱、裸露细支架及通透喷环；源文件保留修改前泡泡炮于独立归档场景，不参与导出。新几何7396三角面、10个材质批次，统一外廓检查通过，未加后背罐或加高白柱。
- 首轮完整检查29/30：tank_motion旧测试依赖名为Body的单网格，材质合批后该命名不再成立。改为逐一记录炮塔所有非后坐网格的世界变换，验证静止壳体均不移动；之后完整检查30/30通过。泡泡炮轮廓修订后再次执行`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs`，30/30 PASS（artifacts/check-report.json）。
- 重新导入后执行integrate_mechanical_family_109.gd，五件共同外廓全部PASS；capture_mechanical_cards_109.gd生成七张512卡片PASS；capture_family_training_109.gd三武器真实训练80tick的后坐/轮带/暂停检查PASS。
- Blender正背侧与Godot实际训练截图已复审，泡泡炮圆舱和镂空喷环在俯视角可辨。`capture_mechanical_family_109.gd`十二组合及机库旋转/小窗口PASS，截图见artifacts/109-*。

## 限制与下一步

等待用户对五件造型和实战连续手感确认；Android触控、安全区、热稳定、性能仍未验收，不宣称移动端里程碑交付。未就绪25件不开放、不扩展玩法。后续以本批Blender源与最新制作手册继续逐件迭代。
