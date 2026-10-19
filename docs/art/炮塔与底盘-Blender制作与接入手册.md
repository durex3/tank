# 炮塔与底盘：Blender制作与接入手册

适用项目：本仓库Godot坦克游戏。更新：2026-10-16。

109更新：本轮三炮塔及两履带车壳已用Blender MCP原创制作，源文件source_art/mechanical-family-v2/mechanical_family.blend，组合检查源文件mechanical_family_review.blend；五份GLB为assets/derived/mechanical-family-v2，正式包装mechanical_v2。主炮/四轮仍为108版本；统一尺寸不变。两履带的轮子、闭合带体和循环履带片复用TrackRig，源目录runtime_tracks.glb只是该运行几何的检查快照。最终结果见109记录。

109重建顺序（独立Blender实例，避免同名源对象冲突）：
1. `blender --background --factory-startup --python tools/build_mechanical_family_109.py --python tools/finish_mechanical_family_109.py`：原创分件建模、保留源文件、导出副本按材质/运动父节点合批。
2. Godot `--headless --editor --import --quit`，再`--headless --script tools/integrate_mechanical_family_109.gd`。
3. `--headless --script tools/export_family_rigs_109.gd`导出准确运行轮带快照，再以Blender打开本批源文件运行`tools/render_mechanical_family_109.py`保存正背侧组合。
4. Godot运行`tools/capture_mechanical_cards_109.gd`、`capture_mechanical_family_109.gd`、`capture_family_training_109.gd`，最后完整`node tools/check.mjs`。

同一运动父节点内按材质合并；不可跨RecoilPivot/Right合并炮管。Blender源文件仍保留可编辑的分件，运行GLB为合批副本。渲染图不是模型，原105/108源文件仍只读保留。


108更新：正式目录已迁移至mechanical_v1，主炮/四轮接入与七件统一外廓见108功能记录。最新炮塔1.038×0.594×1.708米，底盘1.704×0.911×1.904米；以part_size.tres为准。重建先运行prepare_mechanical_108.py，再Godot导入、integrate_mechanical_108.gd、capture_mechanical_cards_108.gd。原105资源保留。下文“尚未接入”描述为107历史状态；其他五件仅尺寸适配，仍需逐件Blender重制。

## 1. 已经确认的方向

用户已认可105制作、106训练试玩中的**分块装甲主炮＋四轮底盘**，要求沿用此流程制作剩余炮塔和底盘。最新样板优先于更早的文字风格讨论与生图方案。

采用Q版轻机械风：大块装甲斜面、局部柔和倒角、清晰机械连接、低矮转环，白色装甲＋深灰机构＋少量黄色识别点。前灯青色、尾灯红色。轮盖白色平盘、黄色外圈、黑色横槽。不要凸出的中心螺帽、后背大箱体、泡泡炮背部蓝罐，也不要靠白色柱子把炮塔垫高。

不是全部做成圆鼓壳，也不是写实军械。形状要清楚，细节只放在炮口、散热口、吊环、光学窗口和必要装甲分块上。普通画面尺寸下能一眼区分不同炮塔。

默认直接用Blender独立建模，**不需要Hyper3D**。可用参考图辅助设计，但不能把PNG称为模型。此前High样板和生成图没有正式接入，不是当前生产基准。不得因工具方便重新回到无控制的文字生模型。

参考MiniTanks的外观和制作规律，不能声称已知对方全部使用Blender。本地提取资源只读分析，没有复制其网格、贴图或代码进入当前样板。

## 2. 换电脑必须带走什么

优先同步完整项目工作副本。只复制本MD无法重现模型或试玩。确认以下文件在公司电脑实际存在，不能只看Git提交状态：

|用途|项目相对路径|
|---|---|
|认可样板源文件|`source_art/mechanical-sample-v1/mechanical_sample.blend`|
|认可主炮|`assets/derived/mechanical-sample-v1/cannon.glb`|
|认可四轮底盘|`assets/derived/mechanical-sample-v1/scout_wheels.glb`|
|正面/背面/侧面|同目录`front.png`、`rear.png`、`side.png`|
|Godot静态预览|同目录`godot-front.png`、`godot-rear.png`|
|几何统计与来源|同目录`report.json`、`provenance.json`|
|可重建脚本|`tools/build_mechanical_sample_105.py`|
|独立渲染检查|`tools/preview_mechanical_sample_105.gd`|
|真实训练试玩|`tools/play_mechanical_sample_106.gd`|
|试玩装配适配器|`presentation/previews/mechanical_sample_mount.gd`|
|Windows试玩入口|`tools/open_mechanical_training.ps1`|
|项目规则|`AGENTS.md`、`docs/rules/`、`docs/art/080-部件统一尺寸契约.md`|
|部件功能目录|`docs/炮塔与底盘类型设计.md`、`content/weapons/`、`content/chassis/`|

`.godot`可以在公司重新导入生成，不当作资源源文件传递；密钥、账号配置和存档不需要带。`artifacts/`被Git忽略，训练截图若需要对照应另行复制。检查`git status`和`git ls-files`，未跟踪的GLB、blend和新工具不会自动随拉取出现；本次没有自动提交或推送。

本机建模使用Blender 5.2.2 LTS；游戏锁定Godot 4.7.2 Compatibility。公司电脑可以使用自己的安装路径；不要照抄本机D盘和E盘路径。建模脚本从当前工作目录读取项目，也支持环境变量`TANK_PROJECT_ROOT`。

跨电脑同步：仓库的`.blend`源文件使用Git LFS，普通GLB直接由Git管理。公司先安装Git LFS，然后执行`git lfs install`、`git pull`、`git lfs pull`。确认`.blend`是实际二进制文件而不是三行LFS指针。自动备份`.blend1/.blend2`不提交；最新源文件保留。

## 3. 尺寸：必须先处理的接入门槛

**认可样板外廓与当前正式统一尺寸不同。不能把试玩成功当成正式尺寸验收完成。**

|对象|宽X|高Y|长Z|状态|
|---|---:|---:|---:|---|
|105主炮原始GLB|1.038|0.594|1.708|认可的造型样板|
|105四轮原始GLB|1.704|0.911|1.919|认可的造型样板|
|当前正式炮塔外廓|1.0296|0.8827276|1.7476878|读取`part_size.tres`为准|
|当前正式底盘外廓|1.6497803|0.9923022|1.9207119|读取`part_size.tres`为准|

这些数字不是每个模型可自由选择的标准。080要求炮塔之间、底盘之间同宽高总长且位置一致。用户认可新样板不等于全套尺寸配置已经迁移。

正式接入前应基于认可造型确定新全套共同外廓，再在同一变更中派生所有当前就绪部件、更新唯一尺寸Resource、卡片和十二混搭验收。不得只改两个目录映射让其余尺寸不一致，也不得修改测试放宽门槛。其余部件尚在制作时，先使用独立候选预览，保留清楚的待验收标记。

禁止整件非等比缩放圆形轮胎、炮口或机械件；禁止看不见的极值网格凑AABB；禁止重新加高底座补齐高度。改造型结构、重新安排面板和独立轴向炮管尺寸，圆形截面保持圆。

轴向：Blender米制、Z向上、+Y向前；GLB进入Godot为Y向上、-Z向前。权威根为identity；正式`TurretSocket=(0,0.76,0)`，正式`Muzzle=(0,0.02,-1.05)`，均不缩放不偏移。

106临时表现适配将炮塔Geometry抬高0.125，与权威0.76挂点组合后为0.885，以还原认可样板装配；这是表现偏移，不是白柱几何，也不是新的权威挂点规则。独立GLB内同名Empty不能代替正式根下的Marker3D。

## 4. 每件模型的执行流程

### A. 先规划，不改变玩法

1. 读AGENTS、架构、代码规范、开发计划、本手册及对应武器/底盘记录。
2. 从实际PartCatalog和Resource核对稳定ID、已有攻击方式、枪口数量和动作需求。类型设计文档含历史提案，以最新功能记录为准。
3. 分析认可样板的正背侧图，写出该部件的主轮廓和独有识别点；只制作一件或小批，审阅后再推广。
4. 先写拆件计划：固定装甲、活动炮管、转环、轮轴/履带、灯、细节。底盘和炮塔必须独立输出。

### B. Blender搭大形

1. 新场景或独立新文件；认可样板和原素材只读，不覆盖。
2. 先做底座/车壳与武器大形，检查比例和装配；不要先堆吊环、螺丝。
3. 用规则截面、斜面和少量装甲块组织形体，给边缘适度倒角，平面保持平整。
4. 炮塔落在薄转环上，侧支架/耳轴承担机械连接；车壳保持宽低。
5. 四个轮胎几何相同，滚动截面为圆，原点在真实轮轴中心；左右与前后位置成对。
6. 完整制作背面与底部。前灯/前装甲和尾灯/散热格栅区分前后，避免两面都像车头。

### C. 材质、法线和细节

复用脚本中的角色配色，不按截图吸取带灯光的像素当基础色。

|角色|脚本线性RGB|粗糙度|金属度|
|---|---|---:|---:|
|白装甲|0.78, 0.80, 0.79|0.48|0.05|
|深灰机构|0.035, 0.047, 0.059|0.55|0.15|
|轮胎|0.013, 0.019, 0.025|0.83|0|
|黄色|0.95, 0.62, 0.025|0.43|0.12|
|钢件|0.21, 0.26, 0.29|0.42|0.40|

当前样板采用纯色PBR，无噪声贴图。先做好几何与材质分区，必要时再加纹理。平面加权法线、倒角过渡与圆柱平滑分别处理；不要把所有面硬切，也不要把平面光顺成鼓包。

炮口要有真实内壁和暗色内衬，不能只有白色孔；散热口表达清楚即可，不必打穿整个壳体。胎纹采用少量大块，一段倒角足够，避免高段数重复细节堆面。

当前样板主炮8588 tris、底盘28884 tris，用户允许超过6000。数字是参考而非硬性目标；应测量最终导出三角面。静态同材质部件可合并减少draw call，但保留活动轴心，不能为了少节点把轮子与车壳焊成一个不可控整体。

### D. 必须保持的命名与运动接口

|部件|节点|要求|
|---|---|---|
|单管炮|`RecoilPivot`|只包含随射击后坐的炮管与相连部件|
|可视出膛|`VisualMuzzle`|位于真实炮口，不代替权威Muzzle|
|双管机炮|`RecoilPivot`、`RecoilPivotRight`及左右可视枪口|成功提交射击后交替，左右独立后坐，沿用TankView契约|
|四轮|`WheelLeftFront`、`WheelLeftRear`、`WheelRightFront`、`WheelRightRear`|完整轮胎、胎纹、轮盖一起挂在轴心下|
|轮盖和螺丝|`Detail_*`等普通名称|不能以`Wheel`开头，现有动态系统会匹配Wheel*|
|正式轮组|`TrackRig` / `ImportedWheelRig`|参数取真实半径和轴距，使用已有提交状态驱动|

父子变换要应用并检查世界坐标。旋转0/45/90/180度时轮轴正交、截面尺寸一致，轮子不能偏心跳动。不要复制当前临时预览代码到battle；运动表现不读取Input、不改伤害或碰撞。

### E. 导出与检查

1. 单独导出炮塔GLB和底盘GLB，选择`use_selection=True`且`use_active_scene=True`。仅选中对象不够，旧场景选中物也可能被错误导出。
2. 导出前检查法线、边界、重复面、穿插、封口、材质；网格流形检查不等于视觉无穿模。
3. 保存可编辑.blend、重建脚本、面数/AABB/轴心报告、来源记录。
4. Blender渲染整车正背侧，必要时真正正交三视图；检查实际装配，而不是只看独立物体。
5. 用Godot Compatibility导入并实拍。图片预览与3D模型交付分开说明。

## 5. 在公司运行当前基准

在仓库根目录打开PowerShell，按公司实际路径设置可执行文件：

```powershell
$blenderExe = '填写本机 Blender 的 blender.exe 完整路径'
$godotExe = '填写本机 Godot 4.7.2 console.exe 完整路径'
$env:TANK_PROJECT_ROOT = (Get-Location).Path
& $blenderExe --background --factory-startup --python tools/build_mechanical_sample_105.py
& $godotExe --headless --path . --editor --import --quit
& $godotExe --path . --script tools/preview_mechanical_sample_105.gd
& $godotExe --path . --script tools/play_mechanical_sample_106.gd
```

上面的重建命令用于重建既有105样板，会写回其派生产物；**制作新部件必须复制脚本，修改输出目录、场景名和稳定ID后再运行**，不要覆盖已认可样板。

完整检查与自动训练实拍：

```powershell
$env:GODOT_BIN = $godotExe
node tools/check.mjs
& $godotExe --path . --script tools/play_mechanical_sample_106.gd --quit-after 600 -- --capture
```

Blender MCP若断开，可以直接走本地后台CLI。Godot启动脚本中的默认路径是本机目录约定，公司可使用上述显式命令，不必改变工程资源路径。

## 6. 正式机库接入步骤

1. 先解决第3节共同尺寸；将派生场景另存新目录，原GLB与旧场景保留。
2. 根Node3D保持identity，根下建立权威Marker3D；Geometry独立承载视觉变换。
3. 对轮组和后坐绑定完成验证，确认来源网格滚动直径和轮轴中心。
4. 更新`presentation/tank_part_catalog.gd`对应ID，不在领域Resource写PackedScene。
5. 使用实际新模型渲染512×512透明部件卡片，另存新目录，更新`HangarPartArtCatalog.ALIGNED_TURRETS`；不要用生成整车图冒充部件卡片。
6. 机库检查默认视角、拖动360度、切换其他部件、全部十二个当前就绪组合、卡片选中/已装配状态；新模型造型不能在卡片里还是旧版。
7. 训练检查移动、转弯、前后方向、单发与双管后坐、真实可视出膛位置、暂停和重建。主炮单发测试用`fire_request_id`，没有`fire_pressed`字段。
8. 跑完整check，修复而非跳过失败，新增三位序号功能记录并更新计划和索引。桌面检查不代替Android真机。

106专用入口目前关闭方向光实时阴影，避开旧Compatibility阴影条纹；这是预览降级，不是阴影根治。正式机库与训练接入要单独检查地面/展台和装甲，不得重复把shadow_normal_bias直接设0后只看坦克。

## 7. 剩余部件制作顺序

先完成已有玩法的部件，再做未就绪外观。ID与行为以当前资源为准，不根据历史表擅改。

|优先项|造型任务|注意|
|---|---|---|
|autocannon|两根清楚可辨的炮管、紧凑壳体、侧面支承|双管独立后坐，不靠叠加长底座|
|scatter|短粗大口径、厚前装甲、近战轮廓|先核对当前枪口与策略，不随意从单管改双管|
|bubble_cannon|大圆短喷口、圆润但有装甲结构|明确禁止背部蓝罐、背包、外置大储液箱|
|light_tracks|低宽车壳、轻型履带、白轮盖黄边黑横槽|无尾部黑大背包，轮子圆且不偏心|
|heavy_tracks|共同外廓下更厚重的护板和连续履带|不能因重型/稀有度把整体放大，不用凸螺帽替代平轮盖|
|其余炮塔/底盘|按22炮塔/10底盘目录逐件规划|模型完成不等于技能就绪，不自动开放配装或训练|

## 8. 可以直接给公司Codex的任务

```text
请读取AGENTS.md、docs/rules/architecture.md、docs/rules/code-style.md、
docs/development-plan.md、docs/art/炮塔与底盘-Blender制作与接入手册.md，
以及105、106及其后最新功能记录。

以用户认可的 mechanical-sample-v1 为唯一当前造型基准，用Blender独立制作
【填写稳定ID和名称】。不需要Hyper3D，不覆盖认可源文件，不复制MiniTanks资源。
先核对最新共同尺寸配置是否已迁移；未迁移则按手册保留独立候选状态，不能
冒充正式机库交付。不得非等比拉伸圆形件或加高白柱凑尺寸。

先分析玩法所需的炮口、后坐、轮组与挂点，列出拆件计划，再建大形、装甲斜面、
倒角和纯色PBR材质。保持白灰黄配色、低转环、明确前后区别。完整制作背面和底部。
所有武器与底盘属于同一尺寸系列，重量/稀有度不通过放大模型表达。

输出独立GLB、可编辑blend、可重建脚本、来源与几何报告，检查轮子滚动、
炮管后坐与法线。渲染正背侧，Godot实际导入审阅，并完成适当回归检查。
如果接入正式目录，同步卡片、机库混搭和真实训练，不改战斗逻辑/碰撞/权威挂点。
我已授权自主完成，不需要逐步确认；实际失败和未验收项如实记录。
```

## 9. 当前交接状态

- 105：原创样板、源文件、两份GLB和实际渲染已完成，用户认可。
- 106：真实训练场专用入口及移动/射击检查已通过；清理9个废弃文件。
- 用户已授权正式机库替换；截至本手册写入，正式目录仍是family_v3，统一尺寸迁移与机库卡片替换尚未完成。后续以更高序号功能记录为准。
- 生图参考v1保留；v2已否决并按授权删除PNG，提示词历史保留。
- 不要把旧103的“进行中”说明、早期22/10目录历史数值或已经结束的Hyper3D任务当成当前交付状态。

## 110 泡泡炮紧凑喷头

用户否决109长杆悬环后，泡泡炮改用`tools/build_bubble_110.py`派生圆润一体喷头，源文件`source_art/bubble-compact-v1/bubble_compact.blend`，包装入口`tools/integrate_bubble_110.gd`。仅泡泡炮替换为`presentation/parts/bubble_compact_v1`；109其它件保持。旧109泡泡炮源与GLB只读保留；不要重跑109后将旧长杆模型重新映射为正式泡泡炮。

## 112 最新泡泡炮

圆盘长颈方案被否决，正式使用`tools/build_bubble_112.py`与`tools/integrate_bubble_112.gd`重建低矮装甲壳＋内嵌圆喷口。源文件`source_art/bubble-armored-v1/bubble_armored.blend`，卡片`capture_bubble_card_112.gd`。旧110与收细试样保留历史，不能映射正式目录。113机库按用户选择关闭实时投影，实战阴影不变。
