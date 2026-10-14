# 069 Rodin整车样板重新生成

日期：2026-10-14。状态：生成完成，待模型与渲染验收。

## 目标与所属层

用户认为现有模型整体不理想，要求使用Hyper3D MCP重新生成，并提供MiniTanks截图作为风格参考。生成主战炮＋轻履带整车候选；仅美术生产资料，不修改运行目录映射、领域数值或权威挂点。

## 接口与变更文件

- Hyper3D Rodin Gen-2.5-High，Raw目标30000面，GLB，texture_delight开启。实际面数与独立部件尚未检查。
- 任务：`4dfce9b9-b0dc-4b5e-88ee-8cf2e1f3b26d`。
- 结果：https://hyper3d.ai/workspace/rodin/4dfce9b9-b0dc-4b5e-88ee-8cf2e1f3b26d
- assets/generated/rodin-sample-v1/：用户参考图裁剪、prompt.txt与provenance.json。原截图及现有模型未覆盖。
- docs/development-plan.md、docs/features/README.md：进度同步。

## 验收与实际结果

- 首次文字请求超过1024字符，被参数校验拒绝，未创建任务；缩短并改为用户参考图驱动后成功。
- 参考裁剪首次Python执行因缺Pillow失败，改用系统sips成功，实际裁剪已审阅。
- 上传成功，rodin_wait返回completed，5/5 pack；get_result返回base_basic_pbr.glb与base_basic_shaded.glb。
- 未下载或接入模型，未宣称实际几何、纹理、拆件或视觉验收通过。`env GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs`：25/25 PASS；`git diff --check`：PASS。自动回归不代表新候选视觉通过。

## 限制与下一步

先审阅生成整车轮廓，再下载验证拓扑、纹理、三角形、底面与背面、模块拆分和枢轴。整车生成不等于独立炮塔/炮管/轮组已具备。进入Godot时需按TankPartCatalog验证装配并检查正常实战尺寸；Android仍待真机。参考来自用户提供的第三方游戏截图，生产使用权利需独立核实。
