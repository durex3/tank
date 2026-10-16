# 099 Blender炮塔与四轮底盘样板

2026-10-15。独立模型、正交视图与Godot预览已制作；用户观感、正式目录接入与Android性能待验收。

## 目标与所属层

按用户截图和建模提示词模板制作象牙白装甲、深灰机械、黑色轮胎和黄色点缀的主战炮塔及四轮底盘。仅source_art、离线tools及presentation预览，不修改战斗、权威射口/碰撞或生产目录。用户允许超过6000 tris，模板同步取消硬上限，不改变080生产统一尺寸规则。

## 交付及接口

- `assets/derived/blender-family-v1/cannon.glb`：3312 tris；`scout_wheels.glb`：7972 tris。实际网格外廓见report.json。
- `source_art/blender-family-v1/tank_modules.blend`：可编辑源文件，活动场景为最终模型，保留原始Scene和迭代场景；导出仅包含活动场景所选模块。
- 米制、Godot前方-Z/上方+Y；炮塔RecoilPivot、VisualMuzzle和四轮Steer/Wheel独立节点。Blender自动追加数字后缀避免覆盖旧对象。轮胎网格TireAssembly与滚动父节点分开。
- 样板炮塔1.0296×0.882728×1.747688米；底盘1.65×0.992302×1.920692米（宽/高/总长），宽度比62.4%。没有整件非等比缩放，尚未迁移全家族生产配置。
- 独立组合预览炮塔座高0.88米，仅为视觉样板，不代表权威TurretSocket。
- 每模块hero/front/right/top/rear实际渲染、assembly组合图、godot-0至3实拍及轮轴检查图。正交视图相机严格轴向，固定ortho_scale 2.6，1200×1000，暗紫背景。
- 六种PBR颜色材质、UV展开、几何倒角；无图片材质或法线贴图，不宣称完成烘焙。
- 新增`presentation/previews/blender_family_preview.gd/.tscn`：拖动旋转、Esc退出，不保存装备或进入战斗。
- 新增`tools/build_blender_tank_099.py`、`render_blender_tank_099.py`、`capture_blender_family.gd`。制作脚本超过300行是离线生成代码，不进入运行时。

## 来源与实际修正

用户截图归档source_art下user-reference.png；imagegen独立参考为cannon-reference.png、chassis-reference.png，提示词归档prompts.json。生成正视初稿有轻微俯视，未作为工程图采用，最终三视图直接从同一模型输出。用户截图权属未独立核实，仅作指定风格参考；网格本轮自行建模，未复用Hyper3D网格。

初稿8028 tris触发6000断言，用户放宽后保留细节。实际渲染发现并修正黄轮毂被遮挡、顶部附件悬空、转台中心未封闭和后部近共面闪烁；清理倒角退化面。网格形态仍比参考更简化，待用户审阅。

## 验收

- Blender MCP执行制作/渲染脚本成功；mesh_qa.json中所有网格开放边、非流形边、零面积面均为0，UV存在，缩放1。装配内部存在正常插接，拓扑报告不等同自动证明全部相交问题。
- 已审阅组合、正面、侧面、顶面、背面及Godot实拍。
- `node tools/check.mjs`：30/30 PASS。后续仅模型小修，再执行针对性导入与实拍验证。
- Godot `--headless --editor --path . --import`成功。
- Godot `--rendering-method gl_compatibility --script tools/capture_blender_family.gd`：`BLENDER FAMILY IMPORT AND PIVOTS PASS`，验证四轮、单炮后坐节点、刚性轴及四方向截图。

限制与下一步：正式射击/轮速事件尚未绑定；全家族混搭、生产统一配置迁移、LOD和Android性能未验收。当前供用户审阅造型，非正式游戏模型替换交付。
