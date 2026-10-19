extends RefCounted
class_name HangarCopy
## Keyed copy, with Chinese fallback until the project locale service is integrated.

const TEXT: Dictionary = {
	"hangar.title": "整备车间", "hangar.subtitle": "自由组合炮塔与底盘，打造你的训练配装",
	"hangar.back": "返回", "hangar.turrets": "选择炮塔", "hangar.chassis": "选择底盘",
	"hangar.cannon": "主战炮", "hangar.autocannon": "速射机炮", "hangar.scatter": "短管散射炮", "hangar.bubble_cannon": "泡泡炮",
	"hangar.light_tracks": "轻型履带", "hangar.scout_wheels": "侦察轮式", "hangar.heavy_tracks": "重型履带",
	"hangar.art": "外观设定图", "hangar.model": "装配模型预览", "hangar.show_model": "查看装配模型",
	"hangar.show_art": "返回外观展示", "hangar.train": "进入试炼场", "hangar.load": "载重  %d / %d",
	"hangar.ready": "承载符合 · 可进入训练", "hangar.overload": "超载 %d · 移速已调整",
	"hangar.note": "已开放 9 种配装训练 · 三大招与三底盘被动可试炼",
	"hangar.hp": "耐久", "hangar.speed": "移速", "hangar.damage": "单弹伤害",
	"hangar.pellets": "每次弹数", "hangar.cooldown": "攻击间隔", "hangar.weight": "炮塔重量",
	"hangar.series": "白瓷系列  /  当前配装", "hangar.selected": "已选择",
}

static func text(key: String) -> String:
	var translated := TranslationServer.translate(key)
	return str(TEXT.get(key, key)) if translated == key else translated

static func part_name(id: StringName) -> String:
	return text("hangar." + str(id))

static func error(code: String) -> String:
	return str({"": "", "part_locked": "尚未解锁", "part_not_ready": "部件待开发", "max_level": "已满级", "insufficient_coins": "金币不足", "stale_level": "等级已变化，请重试", "save_invalid": "存档异常，已阻止覆盖", "save_open_failed": "无法写入存档", "save_write_failed": "写入存档失败", "save_backup_failed": "备份失败", "save_replace_failed": "替换存档失败", "invalid_loadout": "配装不符合承载要求", "already_owned": "已拥有"}.get(code, code))
