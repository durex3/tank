extends Control
class_name DuelPanel
## Displays committed match snapshots; requests new sessions, never mutates scores.

signal duel_requested
signal exit_requested

var _hud := Label.new()
var _overlay := ColorRect.new()
var _title := Label.new()
var _detail := Label.new()
var _rematch := Button.new()
var _block_accept: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_hud.position = Vector2(-370, 64)
	_hud.size = Vector2(346, 80)
	add_child(_hud)
	_build_result()

func show_training() -> void:
	var start := Button.new()
	start.name = "StartDuel"
	start.text = BattleCopy.text(&"duel")
	start.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	start.position = Vector2(-250, 82)
	start.size = Vector2(226, 44)
	start.focus_mode = Control.FOCUS_NONE
	start.pressed.connect(func() -> void: duel_requested.emit())
	add_child(start)

func show_state(state: Dictionary) -> void:
	var seconds: int = state.remaining_seconds
	var mode := "OVERTIME" if state.phase == MatchRuntime.Phase.OVERTIME else "1v1 · FIRST TO %d" % state.target_score
	_hud.text = "%s
PLAYER %d : %d RIVAL  |  %02d:%02d" % [mode, state.scores[0], state.scores[1], seconds / 60, seconds % 60]

func on_event(event: Dictionary) -> void:
	if event.kind != &"match_updated" and event.kind != &"match_finished":
		return
	show_state(event)
	if event.kind != &"match_finished":
		return
	_title.text = "DRAW" if event.winner == -1 else ("VICTORY" if event.winner == 0 else "DEFEAT")
	var player: Dictionary = event.stats[1]
	var rival: Dictionary = event.stats[2]
	_detail.text = "Offline duel · %d : %d
PLAYER  K %d / D %d / Damage %d
RIVAL   K %d / D %d / Damage %d

No coins or XP in this rule trial." % [event.scores[0], event.scores[1], player.kills, player.deaths, player.damage, rival.kills, rival.deaths, rival.damage]
	_block_accept = Input.is_action_pressed("ui_accept")
	_overlay.show()
	_focus_rematch.call_deferred()

func _build_result() -> void:
	_overlay.name = "MatchResult"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.02, 0.04, 0.06, 0.9)
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 360)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	column.add_child(_title)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_detail)
	_rematch.name = "Rematch"
	_rematch.text = "Rematch"
	_rematch.custom_minimum_size.y = 52
	_rematch.pressed.connect(func() -> void: duel_requested.emit())
	column.add_child(_rematch)
	var exit := Button.new()
	exit.name = "ExitMatch"
	exit.text = "Back"
	exit.custom_minimum_size.y = 52
	exit.pressed.connect(func() -> void: exit_requested.emit())
	column.add_child(exit)
	_overlay.hide()

func _input(event: InputEvent) -> void:
	if _overlay.visible and _block_accept and event.is_action("ui_accept"):
		if event.is_action_released("ui_accept"):
			_block_accept = false
		get_viewport().set_input_as_handled()

func _focus_rematch() -> void:
	if is_inside_tree() and _overlay.visible:
		_rematch.grab_focus()
