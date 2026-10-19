# 100 Hyper3D模型Blender拆件修整

2026-10-15。Blender修整、独立导出与Godot机械预览通过；用户观感、正式接入及Android性能待验收。

## 目标与所属层

用户选用Hyper3D造型基础、Blender修整路线，替代099纯几何建模方向。处理097/098的T02双管机炮和C03四轮底盘，保持用户确认的相对尺寸与原PBR外观。所属层为离线美术工具、source_art和presentation独立预览，未改变生产TankPartCatalog、权威射口、碰撞、属性或保存数据。

## 原件与修整

原始`assets/imported/modular-sample-v1/t02_pbr.glb`和`c03_pbr.glb`只读。来源Hyper3D任务、参考提示词及许可信息沿用096/097记录，没有声称新增授权。

1. 焊合位置重合的UV接缝顶点，保留每个面角UV、底色/法线/金属粗糙度贴图。原始松散片段不能代表真实机械零件。
2. 双炮管在深灰接收座内切分，修补内侧切面，增加藏于接收座内的后坐套筒；`RecoilLeft*`与`RecoilRight*`独立，`VisualMuzzleLeft*`与`VisualMuzzleRight*`仅为视觉节点。
3. 首次按轮胎区域拆分时发现前轮/挡泥板粘连及运动碎片，弃用该草稿。最终保留两个完整后轮连通壳体，使用同侧后轮修复前轮；在车身上对融合的前胎执行精确布尔清除并补足内侧，保留外部装甲/挡泥板。
4. 原后轮纵向直径约0.855—0.862米，高向约0.792米，存在椭圆偏差；独立轮胎网格校正为纵/高外廓均0.84米、轴心高度0.42米。对象变换保持刚性；这是轮胎几何修复，不是非等比拉伸整车。原胎块和轮毂细节仍有生成不规则性，不能等同精密解析圆柱。
5. 四个`Steer* → Wheel* → Tire*`节点、补建轮轴、炮管独立后坐，原始造型与贴图尽量保留。未做全模型重拓扑、LOD或贴图重绘。

## 文件与尺寸

- `assets/derived/hyper3d-refined-v1/t02.glb`：21020 tris；`c03.glb`：21622 tris。用户已允许超过6000，不为压面破坏本轮细节。
- `source_art/hyper3d-refined-v1/hyper3d_refined.blend`：可编辑、贴图打包；活动场景是最终修整版，之前场景保留。
- `tools/refine_hyper3d_100.py`、`render_hyper3d_refined.py`：可重建/渲染脚本；构建断言闭合网格和尺寸误差小于1毫米。
- `presentation/previews/hyper3d_refined_preview.gd/.tscn`：独立旋转及机械检查；拖动旋转、空格切换轮动/左右交替后坐，Esc退出。这里只演示动作，不消费/伪造实战事件；失焦停演示。
- `tools/open_hyper3d_refined.ps1`打开预览；`capture_hyper3d_refined.gd`记录四方向与8个运动姿态。
- 同目录含11张Blender实际渲染、Godot四方向和8帧机械检查图、report.json及provenance.json。

最终外廓（宽/高/总长）：炮塔1.029600×0.882728×1.747688米；底盘1.649780×0.992302×1.920712米，与098样板误差小于0.001米。炮塔/底盘宽度比约62.4%。独立样板装配高度0.88米；生产统一配置及权威挂点保持不变，全家族迁移尚未完成。

## 实际验收

- Blender切分后所有导出网格开放边0、非流形边0；原件SHA256与097记录一致。
- 导出器提示同一纹理多个采样节点采用首个采样器；检查所有图像节点均Linear/REPEAT，未发现不一致采样配置。Godot实际贴图显示已审阅。
- `node tools/check.mjs`：30/30 PASS，退出码0。
- Godot Compatibility运行`tools/capture_hyper3d_refined.gd`：输出`HYPER3D REFINED IMPORT / FOUR WHEELS / INDEPENDENT RECOIL PASS`。四轮节点、左右后坐独立与复位、轴向正交/单位缩放断言通过。
- 已审阅静止正背面、两种运动姿态及Blender渲染；最终轮转不再携带装甲碎面，未见切口明显露洞。此项不等同所有转向角度和全动画范围均无穿模。

限制与下一步：生成装甲表面仍有软化和不规则细节，背部原生圆孔设计保留；没有宣称美术彻底精修。正式事件绑定、前轮转向全行程、十二组合、Android帧率与热稳定仍待验收。用户审阅本轮效果后继续细修及生产接入。
