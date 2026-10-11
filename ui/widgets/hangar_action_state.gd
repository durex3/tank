extends RefCounted
class_name HangarActionState
## Present service eligibility without changing progression or currency.

static func configure(screen: Control, kind: int, pending: bool, owned: bool) -> bool:
	var source: Button = screen.progress_panel.actions[kind]
	var eligible: bool = not pending and not source.disabled
	screen.upgrade_button.get_parent().show()
	screen.part_info.hide()
	screen.upgrade_button.disabled = not eligible
	screen.upgrade_button.text = "升级" if owned and not pending else ("解锁" if eligible else "未解锁")
	var cost: String = source.text.get_slice(" · ", 1)
	screen.upgrade_fee.text = "金币 " + cost if not pending and not cost.is_empty() else ""
	screen.details_panel.dialog_upgrade.text = screen.upgrade_button.text
	screen.details_panel.dialog_upgrade.disabled = not eligible
	return not pending and source.text != "已满级"
