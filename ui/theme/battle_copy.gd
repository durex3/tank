extends RefCounted
class_name BattleCopy
## Centralized desktop training HUD text. Gameplay values remain session-owned.

const TEXT: Dictionary = {
	&"back": "返回",
	&"touch": "触控模式",
	&"pause": "暂停 · Esc",
	&"sparring": "开始对练",
	&"sparring_active": "对练进行中",
	&"duel": "计时对局 · 1v1",
	&"stats": "%d × %d 伤害 · %.2f 秒间隔 · %.1f 米/秒",
	&"health_training": "耐久 %d / %d · 训练无收益",
	&"fired": "已发射 %d 颗 · 间隔 %.2f 秒",
	&"hit": "命中 %d · 目标 %d：%d / %d",
	&"died": "目标 %d 击毁 · 3 秒后重建",
	&"respawned": "目标 %d 重建 · 保护期内禁止开火",
	&"rejected": "开火未执行：",
	&"health_sparring": "耐久 %d / %d · 对手巡逻中",
	&"health": "耐久 %d / %d",
	&"health_ready": "耐久 %d / %d · 可行动",
	&"health_match": "耐久 %d / %d · 离线计时对局",
	&"rebuild_suffix": " · 3 秒后重建",
	&"protected_suffix": " · 保护期内禁止开火",
	&"controls": "WASD 移动 · 鼠标瞄准",
	&"hold": "按住开火",
	&"release": "松手开火",
}

static func text(key: StringName) -> String:
	var translated := TranslationServer.translate(key)
	return TEXT.get(key, str(key)) if translated == str(key) else translated
