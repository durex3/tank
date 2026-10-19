# 030-macOS中文字体与预览尺寸回归

日期：2026-10-12。

目标：修复macOS机库技能中文方框与预览尺寸回归失败，保留Windows字体优先级。

所属层及接口：UI/Theme。HangarStyle.create显式配置RichTextLabel.normal_font和bold_font；macOS优先Hiragino Sans GB，其次PingFang SC/Heiti SC，Windows仍优先微软雅黑。

原因：原主题只设default_font，富文本粗体使用独立默认字体槽。macOS字体回退缺少部分中文；字体度量也影响空/非空状态的最小高度，造成待开发部件切换时预览高度310→311。为普通和粗体提供一致中文字体后，原始严格尺寸断言通过，无需放宽容差或跳过测试。本机单独检查发现PingFang SC返回“敌”“稳”无字形，Hiragino Sans GB有字形，因此采用后者优先。

变更文件：ui/theme/hangar_style.gd、tests/presentation/hangar_directory_tests.gd、计划/索引/交接。

验收：
- 原机库目录测试保留尺寸相等断言，修复后PASS。
- 新增普通/粗体两个槽对全部32项技能摘要汉字的has_char覆盖断言。
- Godot tools/capture_hangar_workbench.gd：PASS；已审阅实际macOS Compatibility整备及详情截图，技能中文正常、操作按钮可见。
- 一次沙盒直接测试出现日志写入与证书环境错误；沙盒外重跑目录测试PASS且无该错误。临时诊断脚本已移除。
- GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot node tools/check.mjs：最终21/21全部PASS，包含新增字体覆盖与原尺寸严格断言。git diff --check通过。

限制与下一步：本次没有打包系统字体，Windows使用原字体优先级但未在本轮实机复验；Android字体与安全区仍待验收。下一编号031。
