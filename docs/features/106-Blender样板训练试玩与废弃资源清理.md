# 106 Blender样板训练试玩与废弃资源清理

状态：专用训练试玩入口已实现，自动动作验收通过；正式机库替换和统一外廓仍待完成。用户认可105样板，要求接入游戏看看，并删除不用的资源。

## 范围与接口

- `presentation/previews/mechanical_sample_mount.gd`：开发预览装配适配器，替换TankView的表现子节点并绑定既有轮组/后坐，不更改目录映射或定义。
- `tools/play_mechanical_sample_106.gd`：真实MovementSession训练场，主炮＋四轮底盘，WASD屏幕方向移动、鼠标瞄准和单发请求保持原系统；暂停与技能沿用原会话。
- `tools/open_mechanical_training.ps1`：打开专用试玩入口。机库仍使用既有资源，本次不是正式全套目录迁移。
- 权威TurretSocket=(0,.76,0)、Muzzle=(0,.02,-1.05)及根变换不变；新炮塔Geometry独立偏移.125，使已认可装配高度.885保持不变，未增加底座几何。外廓不冒充080验收通过。
- 四个轮轴重设表现父节点，轮盖等细节改名以免被旧Wheel通配符当作轮轴；轮组半径.402，轴距参数.63。实际后坐只由成功提交事件驱动。

## 验收

完整 `node tools/check.mjs` 通过。`--script tools/play_mechanical_sample_106.gd -- --capture`通过80tick移动和射击：观察到炮管后坐、完整轮组转动，权威射口变换保持不变。截图`artifacts/106-training-*.png`，日志`artifacts/106-training.log`。

初次自动检查没有提交单发request，误只设置fire_held；随后错误使用不存在的fire_pressed字段，均未通过。改为正式fire_request_id后通过。轮节点owner警告已通过重设owner解决。这些失败均为开发预览/验收脚本问题，未修改战斗规则。

Compatibility原训练场实时阴影有明显条纹，调整偏移和单级正交阴影仍存在；本专用入口暂关闭方向光实时阴影并提高光强。不是完整阴影修复，不改正式场景配置；正式接入前需修复该遗留问题。Android仍未验收。

## 实际删除

用户明确授权删除不用的资源。清理前检查app/presentation/session/content/ui/tests/tools/project.godot没有引用两个废弃路径；所有删除路径解析后限定在工作区。删除9个文件，共约11.4MiB：

- 用户否决的rounded-tank-reference-v2三张PNG及其.import。
- 已由High方案替代且未被采用的toy-style-v1/cannon.glb及.import。
- mechanical_sample.blend1自动备份，保留当前.blend。

明细`artifacts/106-cleanup.json`。保留提示词/任务记录、认可的v1参考、当前GLB与源文件；family_v3等仍被正式游戏引用，未删除。未清空.godot或原始外部资源。
