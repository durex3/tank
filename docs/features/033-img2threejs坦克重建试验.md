# 033-img2threejs坦克重建试验

日期：2026-10-12。状态：试验已执行，模型待验收，未达到参考图预期。

目标：安装用户指定的 img2threejs，并以主战炮＋轻型履带设定图生成一个可查看的试验模型。

所属层：独立美术试验，不接入领域、会话或游戏表现目录。接口：Three.js工厂createIvoryVanguardTankModel、sculptRuntime.nodes、独立炮塔旋转与GLB导出。

来源：用户指定 https://github.com/img2threejs/img2threejs ，安装至用户技能目录img2threejs（SKILL标记2.0）；输入为项目既有assets/tanks/cannon-hero-v1.png，原图只读。本次没有新生PNG冒充模型。建模说明为artifacts/tank-sculpt/image-analysis.md及object-sculpt-spec.json：象牙白/金色坦克，圆润炮塔、中空炮口、双侧履带；隐藏背面推测。详细参数与重建脚本保存在author_spec.py。

变更文件：本记录、开发计划、功能索引；试验产物在忽略目录artifacts/tank-sculpt。Python独立3.12.15位于/private/tmp/tank-python，未替换系统Python；此工具链为临时安装，后续使用需确认路径仍存在。Three.js0.180.0、Vite6.1.0、Playwright1.51.1仅用于独立预览。

实际结果：参考图准入通过；严格spec校验PASS；浏览器软件WebGL真实渲染主视角/侧面/背面；多角度检查无塌陷（背景占比使其只能作粗筛）。GLB已导出165068字节。初次transform.scale覆盖dimensions导致比例错误，修正后重新生成并审阅comparison.png。基础块面仍缺轮组、舱盖、履带分节和装甲结构，炮塔椭圆且白色过亮；视觉估计0.4，不接受为正式资产。Tier1首轮失败：IoU0.485、scaleDelta0.133、缺map-stripped证据；未伪造通过，未解锁后续细节阶段，reviewHistory已记录stop。

查看：http://127.0.0.1:5199/（本地Vite服务运行期间有效）；artifacts/tank-sculpt/comparison.png；tank-blockout.glb。复现：进入preview目录，使用Node23运行node_modules/vite/bin/vite.js --host 127.0.0.1 --port 5199；capture.mjs使用本机Chrome及软件WebGL截图，export.mjs导出当前几何。

验收：GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs：21/21 PASS；git diff --check通过，结果见本轮check-report.json；此美术试验不代表Android、性能、真实装配接口或正式资产验收。

限制与下一步：不能从本次基础块面断言该工具最终质量上限；目前效果不满足用户设定图预期。若继续，需要按真实失败项修正基础形体和取景后通过门槛，再逐阶段生成结构与材质；或采用人工建模/专用重建模型并保持炮塔与底盘分离接口。下一编号034。
