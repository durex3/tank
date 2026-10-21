# 136 Hyper3D主炮修整候选

状态：候选派生、独立试装和卡片渲染已实现。桌面检查通过；用户观感及Android待验收，未替换生产模型/卡片。

## 目标、所属层与接口

用户同意用参考项目图像尝试Hyper3D，并提供生成的PBR/Shaded GLB，随后确认在Blender修整。仅涉及离线美术工具和表现候选，不修改领域、输入、技能、伤害、正式目录映射或存档。

原文件位于用户Downloads/487d6b33-e68a-4f2b-ae8f-654fd32c2452，始终只读。Hyper3D任务487d6b33-e68a-4f2b-ae8f-654fd32c2452使用Gen-2.5-High、Raw、目标20000面、GLB、texture_delight=true；图像输入为参考项目turrets_Weapon_t_1原图，用户已明确允许。原参考不是本项目原创，派生仅作研究候选，不声明第三方资产已获正式发行许可。

## 变更文件与实际修整

- tools/refine_hyper3d_cannon_136.py：Blender 5.2.2读取原始PBR，先导出原比例修色研究版cannon_native.glb，再导出装配候选cannon.glb；去掉原绿色纹理/烘焙明暗/法线贴图，重新使用象牙白、深灰、黑色内膛和黄色炮口独立材质。
- 原壳体三角网格轻量松弛，切除原底环/顶盖区并封口；只对装甲壳做结构比例适配，独立重建底环、圆舱盖、固定接收座和空心炮管。炮根原有毛糙凸起通过局部前脸重建去除；炮管是具有内膛和后壁的实际网格。
- RecoilPivot/VisualMuzzle保持既有动作接口，固定接收座属于车壳，只有炮管后坐。圆舱盖、底环和炮管均不处于壳体非等比变换下。
- assets/derived/hyper3d-cannon-study-v1：独立GLB与provenance.json，含原文件SHA256、生成ID及来源。候选以16方向局部遮蔽顶点色复用现有每实例材质，不使用2K输入贴图。
- source_art/hyper3d-cannon-study-v1/cannon_study.blend：独立可编辑源；清除未使用的导入网格/材质/贴图，将源文件从约8.4MiB降至约1.2MiB，原Downloads输入不复制到Git。
- presentation/parts/hyper3d_cannon_study_v1/cannon.tscn：仅候选包装，根变换为单位，权威Muzzle=(0,.02,-1.05)不变，完整外廓继续匹配part_size.tres。正式TankPartCatalog/HangarPartArtCatalog仍保持135。
- tools/capture_hyper3d_cannon_136.gd：原图生成结果/原比例修色/装配候选三个方向对照、当前135/候选整车对照、后坐峰值与透明512/128卡片，输出忽略的artifacts/136-*。

## 验收命令与实际结果

- `/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/refine_hyper3d_cannon_136.py`：最终退出0，派生GLB和源文件成功生成。
- `Godot --headless --editor --path . --import`：退出0，无ERROR。
- `Godot --path . --script tools/capture_hyper3d_cannon_136.gd`：最终退出0，所有专项断言通过，无SCRIPT ERROR/ERROR/Parse Error；已审阅最终整车对比、后坐画面及小尺寸卡片。工具断言完整外廓0.0002米门槛、圆形炮管截面、独立后坐/回位、同tick冻结、可视射口随动及权威射口不动、卡片透明和8px留白。
- `env GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs`：33/33通过，退出0，日志/private/tmp/tank-136-check.log。此全量检查保护现有生产行为；候选通过上述专项单独检查。
- 首轮尺寸检查虽通过，实际画面暴露壳体Y轴反向后法线未重算的破面，已修正并重新渲染；没有把首轮PASS当视觉通过。后续继续局部重建炮根，最后重建炮根前脸后重新导入/渲染，已审阅最终截图。

## 限制和下一步

装配候选比原模型明显低矮，顶部舱盖与炮管已重建，不能称为原比例完整保留或只换颜色。原比例修色版单独保留供比较；残余侧面小凹凸、整体造型及图标质量仍以用户实际观感为准，未宣称达到参考品质。未做正式换装、全家族扩展或Android验收；先依据修色/适配对照决定是否继续。
