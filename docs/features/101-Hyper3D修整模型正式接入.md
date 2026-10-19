# 101 Hyper3D修整模型正式接入

2026-10-15。用户认可100效果并要求接入。正式机库、训练场及模型卡片接入完成，桌面验收通过；Android及接入后用户试玩待验收。

## 目标、所属层和接口

将100修整双管机炮/四轮底盘用于正式`autocannon`/`scout_wheels`，复用TankView、TankRecoil、TankTracks与ImportedWheelRig。仅presentation和离线工具变化，不修改战斗、移动、伤害、成长、拥有状态或存档。

新派生场景全部位于`presentation/parts/refined_v1`，原始模型和此前包装场景保留。新炮塔节点映射为`RecoilPivot`、`RecoilPivotRight`、`VisualMuzzle`、`VisualMuzzleRight`、`Body`；轮节点保留网格轴心、提升至底盘根下供ImportedWheelRig处理，轮半径0.42米、半轮距0.627米，前轮转向与刚性滚动复用原逻辑。

根变换identity；权威Muzzle=(0,0.02,-1.05)、TurretSocket=(0,0.76,0)不变。炮塔Geometry局部上移0.12米，最终组合与100已确认预览一致。原PBR材质保留，未添加Visual节点触发旧模型的材质清洁替换。后坐仍只响应成功提交事件，暂停、死亡/重建/换件的清理复用既有实现。

## 统一尺寸迁移

不能只替换两件而让其余同类大小不一致。`content/presentation/part_size.tres`迁移到已确认样板外廓：

- 炮塔AABB：位置(-0.5148,0.12,-1.1374642)，大小(1.0296,0.8827276,1.7476878)。
- 底盘AABB：位置(-0.82478017,约0,-0.9603659)，大小(1.6497802,0.9923022,1.9207118)。

其余三炮塔保持原壳体等比缩放，通过独立浅色八边形装甲底座补齐高度、炮管部件平移补齐总长；不将圆形炮口非等比拉伸。轻/重履带车壳按共同外廓校准，轮组独立重建，保持圆形轮轴与米制半径，通过轨道长度适配总长。所有七件实测位置/宽高总长通过既有0.0002米容差检查，十二种装配已实拍。

最初履带离散采样造成约0.00045米总长误差、派生断言失败；依据实际静止履带外廓迭代校正后通过。最初旧炮塔黑色底座显得过于细长，审阅后改为宽肩浅色装甲底座；这是旧造型的过渡适配，非宣称其余五件也已完成Hyper3D重制。

## 文件

- 修改`presentation/tank_part_catalog.gd`：七件映射到refined_v1。
- 修改`content/presentation/part_size.tres`：唯一正式尺寸配置。
- 新增`tools/integrate_refined_parts.gd`：离线派生、节点适配与尺寸检查，不读当前Catalog作来源，避免重复累计缩放。
- 修改`presentation/hangar_part_art_catalog.gd`，新增`assets/derived/refined-cards-v1`两张512×512透明模型实拍卡片；原插画保留。
- 新增`tools/capture_refined_cards.gd`、`capture_refined_integration.gd`；复用`capture_handling_feedback.gd`验收实战。捕获机库使用独立fixture存档，不改用户装备或金币。
- 更新AGENTS、080美术契约、开发计划、功能索引和来源记录。

## 实际验收

- `tools/integrate_refined_parts.gd`：`REFINED PRODUCTION DERIVATION PASS`，七件统一位置/尺寸输出正确。
- `node tools/check.mjs`：30/30 PASS，包含正式目录、挂点、可视枪口、双管成功发射交替、前轮转向、源轮直径/轴心、刚性转动、实例独立、暂停/重建、尺寸及机库等回归。
- 最终底座材质/卡片变更后再次运行`part_size_tests.gd`、`hangar_art_tests.gd`通过。
- `capture_refined_integration.gd`：十二组合及真实机库截图PASS。首次检查图受窗口高度裁剪，改为4列×3行后重新输出完整图，已审阅。
- `capture_handling_feedback.gd`：80个实际模拟tick和渲染过程，保留14帧射击、转向、倒车，`HANDLING CAPTURE: PASS`；已审阅正常训练视角。
- `capture_refined_cards.gd`：两张新部件卡片PASS，实际机库卡片与新模型一致。

证据：`artifacts/101-twelve-combinations.png`、`101-hangar.png`、`101-hangar-rear.png`、`handling-*.png`。截图是忽略产物；正式资源与来源另存。

限制：用户本轮认可的是100样板，接入后的混搭/手感需继续试玩；生成装甲仍有不规则细节。Android触控、帧率、热稳定及移动端纹理预算未验收，不以桌面30项替代。未解锁部件仍按原规则解锁，没有为看模型修改用户存档。
