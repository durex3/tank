extends Control
## Training page: letterboxed world, committed HUD feedback and device input forwarding.

signal back_requested
signal duel_requested(weapon_id: StringName, chassis_id: StringName, touch_mode: bool)

var session := MovementSession.new()
var _container := SubViewportContainer.new()
var _viewport := SubViewport.new()
var _centers: Array[Vector2] = []
var _combat_status := Label.new()
var _health_status := Label.new()
var _sparring_button := Button.new()
var _cooldown := ProgressBar.new()
var duel_panel := DuelPanel.new()
var pause_overlay := PauseOverlay.new()

func _ready() -> void:
	theme = HangarStyle.create()
	add_theme_font_size_override("font_size", 16)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.stretch = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	_viewport.size = Vector2i(1280, 720)
	_viewport.own_world_3d = true
	_container.add_child(_viewport)
	_viewport.add_child(session)
	# Input belongs to the outer viewport; forwarding is explicit.
	session.touch.set_process_input(false)
	_build_toolbar()
	_build_feedback()
	_build_pause_overlay()
	_build_duel_panel()
	resized.connect(_layout)
	_layout()

func _build_toolbar() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.06, 0.10, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	backdrop.offset_bottom = 66
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var bar := HBoxContainer.new()
	bar.position = Vector2(24, 16)
	bar.add_theme_constant_override("separation", 18)
	add_child(bar)
	var back := Button.new()
	back.text = BattleCopy.text(&"back")
	back.pressed.connect(_on_back)
	bar.add_child(back)
	var hint := Label.new()
	hint.text = "%s · %s · %s" % [HangarCopy.part_name(session.weapon.id), BattleCopy.text(&"controls"), BattleCopy.text(&"hold" if session.weapon.continuous_fire else &"release")]
	bar.add_child(hint)
	var mode := CheckButton.new()
	mode.text = BattleCopy.text(&"touch")
	mode.button_pressed = session.use_touch
	mode.toggled.connect(_set_touch)
	bar.add_child(mode)
	var pause_button := Button.new()
	pause_button.text = BattleCopy.text(&"pause")
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(session.pause.bind(&"manual"))
	bar.add_child(pause_button)
	_sparring_button.name = "StartSparring"
	_sparring_button.text = BattleCopy.text(&"sparring")
	_sparring_button.focus_mode = Control.FOCUS_NONE
	_sparring_button.pressed.connect(_start_sparring)
	bar.add_child(_sparring_button)

func _build_feedback() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 78)
	panel.size = Vector2(410, 114)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", HangarStyle.panel())
	add_child(panel)
	_combat_status.position = Vector2(30, 88)
	_combat_status.text = BattleCopy.text(&"stats") % [session.weapon.damage, session.weapon.pellet_count, float(session.actor.stats.interval_ticks) / BattleClock.TICKS_PER_SECOND, session.actor.stats.move_speed]
	add_child(_combat_status)
	_cooldown.position = Vector2(30, 163)
	_cooldown.size = Vector2(380, 12)
	_cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cooldown.show_percentage = false
	add_child(_cooldown)
	_health_status.position = Vector2(30, 128)
	_health_status.text = BattleCopy.text(&"health_training") % [session.actor.health.hp, session.actor.health.max_hp]
	add_child(_health_status)
	session.simulation.events.published.connect(_on_combat_event)

func _build_pause_overlay() -> void:
	pause_overlay.match_mode = session.match_rules != null
	add_child(pause_overlay)
	pause_overlay.resume_requested.connect(session.resume)
	pause_overlay.exit_requested.connect(_on_back)
	session.phase_changed.connect(_on_phase_changed)

func _input(event: InputEvent) -> void:
	# Releases must clear held fire even when a GUI control consumes the event.
	if session.enabled and not session.use_touch and event.is_action_released("fire"):
		session.desktop.handle_event(event)
	if session.can_control and session.use_touch and session.touch.handle_event(event):
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if session.phase == MovementSession.Phase.PAUSED:
			session.resume()
		else:
			session.pause(&"manual")
		get_viewport().set_input_as_handled()
		return
	if session.enabled and not session.use_touch:
		session.desktop.handle_event(event)

func _process(_delta: float) -> void:
	session.mouse_viewport_position = (get_local_mouse_position() - _container.position) / _container.size * Vector2(_viewport.size)

func _draw() -> void:
	if not session.use_touch or _centers.size() != 3:
		return
	var sticks: Array[Vector2] = [session.touch.state.move_vector, session.touch.state.aim_drag, session.touch.state.ability_drag]
	for slot: int in range(3):
		var color := Color("55cfd5") if slot == 0 else Color("e9ba65")
		draw_circle(_centers[slot], 64, Color(color, 0.15))
		draw_arc(_centers[slot], 64, 0, TAU, 48, color, 2, true)
		draw_circle(_centers[slot] + sticks[slot] * 64, 18, color)

func _layout() -> void:
	var scale_factor := minf(size.x / 1280.0, size.y / 720.0)
	_container.size = Vector2(1280, 720) * scale_factor
	_container.position = (size - _container.size) * 0.5
	_centers = [Vector2(110, size.y - 110), Vector2(size.x - 110, size.y - 110), Vector2(size.x - 110, size.y - 290)]
	var regions: Array[Rect2] = []
	for center: Vector2 in _centers:
		regions.append(Rect2(center - Vector2(80, 80), Vector2(160, 160)))
	session.touch.state.configure(regions)
	session.touch.viewport_to_logical = get_global_transform_with_canvas().affine_inverse()
	queue_redraw()

func _set_touch(value: bool) -> void:
	session.set_touch_mode(value)
	queue_redraw()

func _on_back() -> void:
	session.stop()
	back_requested.emit()

func _on_combat_event(event: Dictionary) -> void:
	_update_health(event)
	match event.kind:
		&"weapon_fired":
			if event.source_id != session.actor.state.entity_id:
				return
			_combat_status.text = BattleCopy.text(&"fired") % [event.pellet_count, float(session.actor.stats.interval_ticks) / BattleClock.TICKS_PER_SECOND]
		&"damage_applied":
			_combat_status.text = BattleCopy.text(&"hit") % [event.actual_damage, event.target_id, event.hp, event.max_hp]
		&"entity_died":
			_combat_status.text = BattleCopy.text(&"died") % event.target_id
		&"entity_respawned":
			_combat_status.text = BattleCopy.text(&"respawned") % event.target_id
		&"cooldown_changed":
			_cooldown.max_value = event.interval_ticks
			_cooldown.value = event.interval_ticks - event.remaining_ticks
		&"fire_rejected":
			_combat_status.text = BattleCopy.text(&"rejected") + str(event.reason)

func _on_phase_changed(phase: MovementSession.Phase, reason: StringName) -> void:
	if phase == MovementSession.Phase.PAUSED:
		pause_overlay.show_paused(reason)
	else:
		pause_overlay.dismiss()
	queue_redraw()

func _start_sparring() -> void:
	var error := session.start_sparring()
	if not error.is_empty():
		_combat_status.text = error
		return
	_sparring_button.disabled = true
	_sparring_button.text = BattleCopy.text(&"sparring_active")
	_health_status.text = BattleCopy.text(&"health_sparring") % [session.actor.health.hp, session.actor.health.max_hp]

func _update_health(event: Dictionary) -> void:
	if event.get("target_id", -1) != session.actor.state.entity_id:
		return
	if event.kind == &"damage_applied" or event.kind == &"entity_respawned":
		_health_status.text = BattleCopy.text(&"health") % [event.hp, event.max_hp]
		if event.hp == 0:
			_health_status.text += BattleCopy.text(&"rebuild_suffix")
		elif event.get("protected", false):
			_health_status.text += BattleCopy.text(&"protected_suffix")
	elif event.kind == &"protection_changed":
		_health_status.text = BattleCopy.text(&"health_ready") % [session.actor.health.hp, session.actor.health.max_hp]

func _build_duel_panel() -> void:
	add_child(duel_panel)
	duel_panel.duel_requested.connect(_request_duel)
	duel_panel.exit_requested.connect(_on_back)
	if session.simulation.match_runtime == null:
		duel_panel.show_training()
	else:
		_sparring_button.hide()
		_health_status.text = BattleCopy.text(&"health_match") % [session.actor.health.hp, session.actor.health.max_hp]
		duel_panel.show_state(session.simulation.match_runtime.snapshot())
		session.simulation.events.published.connect(duel_panel.on_event)

func _request_duel() -> void:
	if session.phase == MovementSession.Phase.STOPPED:
		return
	session.stop()
	duel_requested.emit(session.weapon.id, session.chassis.id, session.use_touch)
