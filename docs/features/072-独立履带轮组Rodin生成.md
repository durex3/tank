# 072 独立履带轮组Rodin生成

日期：2026-10-14。状态：生成完成，未接入、待结构与视觉验收。

## 目标、层、接口

用户确认使用MCP单独生成真实3D履带轮组。Hyper3D Rodin Gen-2.5-High，Raw目标12000面、PBR GLB、纹理去光照；只生成单侧模块，要求三个独立轮盘、独立履带带体及支架，不含炮塔/车身，左右计划镜像复用。属于美术资源生产，不改权威规则。

## 文件与执行

- assets/generated/rodin-tracks-v1/reference.png：裁自用户原参考，原图不改写。
- 同目录prompt.txt、provenance.json：完整提示词与来源。
- 任务`45223830-6a7a-4b11-a9bb-ab554b1a9675`；rodin_wait返回completed (pack 5/5)。结果：https://hyper3d.ai/workspace/rodin/45223830-6a7a-4b11-a9bb-ab554b1a9675 。get_result提供PBR与shaded GLB。
- `env GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs`：25/25 PASS；`git diff --check`：PASS；不代表新模型结构通过。
- 首次提示词1032字符被1024字符校验拒绝；缩短后创建任务成功。参考上传成功。
- 同步docs/development-plan.md及features/README.md。

## 限制与下一步

2026-10-14实物检查修订：用户截图确认生成完整底盘，包含车身与炮塔座，未达单侧模块目标。下载GLB检查为12000三角形、1节点、1网格；按位置五位小数焊接拓扑检测为单一连通体，轮盘未独立。报告assets/imported/rodin-tracks-v1/inspection.json。未替换运行资源。记录追加首次Python写入因编码错误失败，改用apply_patch成功。

用户提供MiniTanks只读资源分析：tank.tscn配置Assembler、Motor、TurretAim、Weapon、BodySway、TurretRecoil等组件。formal轻履带Caterpillar_1_LP.tres引用H01_rolling.glb及tracked.tres，default_mount位置(0,1.105,-0.12)；主战炮Weapon_t_1.tres引用T03_hybrid.glb，独立muzzle_offset=(0,0.416,2.3055)。存在rolling_animator.gdc/remap，未反编译，不能确认算法或内部轮组节点。原GLB不在解包目录，仅.import与压缩.scn，未复制对方资源。分析不构成生成模型通过验收。

提示词不保证独立网格或正确枢轴。先看风格和轮廓，再检查完整背面、圆度、轮轴、带体空腔、贴图、实际三角形及拆件；必要时BANG。合格后才能替换071失败候选并做差速/暂停/生命周期验收，Android门槛保留。
