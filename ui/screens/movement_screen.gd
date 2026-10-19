extends Control
## Training page: letterboxed world, committed HUD feedback and device input forwarding.

signal back_requested
signal duel_requested(weapon_id: StringName, chassis_id: StringName, touch_mode: bool)

const VIEW_STYLE: TrainingViewStyle = preload("res://content/presentation/training_view.tres")

var view_style: TrainingViewStyle = VIEW_STYLE
var session := MovementSession.new()
var _container := SubViewportContainer.new()
var _viewport := SubViewport.new()
var _centers: Array[Vector2] = []
var training_hud := TrainingHud.new()
var touch_overlay := TrainingTouchOverlay.new()
var _combat_status: Label
var _health_status: Label
var _sparring_button: Button
var _cooldown: ProgressBar
var duel_panel := DuelPanel.new()
var pause_overlay := PauseOverlay.new()
var ability_hud := AbilityHud.new()

func _ready() -> void:
	theme = HangarStyle.create()
	add_theme_font_size_override("font_size", 16)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.stretch = false
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	_viewport.size = view_style.render_size
	_viewport.msaa_3d = view_style.msaa
	_viewport.own_world_3d = true
	_container.add_child(_viewport)
	_viewport.add_child(session)
	# Input belongs to the outer viewport; forwarding is explicit.
	session.touch.set_process_input(false)
	_build_training_hud()
	_build_ability_hud()
	touch_overlay.state = session.touch.state
	add_child(touch_overlay)
	touch_overlay.visible = session.use_touch
	session.touch.state_changed.connect(touch_overlay.queue_redraw)
	_build_pause_overlay()
	_build_duel_panel()
	resized.connect(_layout)
	_layout()

func _build_training_hud() -> void:
	training_hud.weapon_id = session.weapon.id
	training_hud.continuous = session.weapon.continuous_fire
	training_hud.touch_mode = session.use_touch
	training_hud.match_mode = session.match_rules != null
	add_child(training_hud)
	training_hud.back_requested.connect(_on_back)
	training_hud.pause_requested.connect(session.pause.bind(&"manual"))
	training_hud.touch_requested.connect(_set_touch)
	training_hud.sparring_requested.connect(_start_sparring)
	_combat_status = training_hud.combat_status
	_health_status = training_hud.health_status
	_sparring_button = training_hud.sparring
	_cooldown = training_hud.cooldown
	_combat_status.text = BattleCopy.text(&"stats") % [session.weapon.damage, session.weapon.pellet_count, float(session.actor.stats.interval_ticks) / BattleClock.TICKS_PER_SECOND, session.actor.stats.move_speed]
	_health_status.text = BattleCopy.text(&"health_training") % [session.actor.health.hp,session.actor.health.max_hp]
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
		touch_overlay.queue_redraw()

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
	session.mouse_viewport_position = _container.get_local_mouse_position() / _container.size * Vector2(_viewport.size)

func _layout() -> void:
	var scale_factor := minf(size.x / 1280.0, size.y / 720.0)
	_container.size = Vector2(_viewport.size)
	_container.scale = Vector2.ONE * scale_factor * 1280.0 / float(_viewport.size.x)
	_container.position = (size - Vector2(1280, 720) * scale_factor) * 0.5
	_centers = [Vector2(110, size.y - 110), Vector2(size.x - 110, size.y - 110), Vector2(size.x - 110, size.y - 290)]
	touch_overlay.centers = _centers
	var regions: Array[Rect2] = []
	for center: Vector2 in _centers:
		regions.append(Rect2(center - Vector2(80, 80), Vector2(160, 160)))
	session.touch.state.configure(regions)
	session.touch.viewport_to_logical = get_global_transform_with_canvas().affine_inverse()
	_layout_ability()
	touch_overlay.queue_redraw()

func _set_touch(value: bool) -> void:
	session.set_touch_mode(value)
	training_hud.set_touch_mode(value)
	touch_overlay.visible = value and session.enabled
	_layout_ability()
	touch_overlay.queue_redraw()

func _on_back() -> void:
	session.stop()
	back_requested.emit()

func _on_combat_event(event: Dictionary) -> void:
	_update_health(event)
	match event.kind:
		&"weapon_fired":
			if event.source_id != session.actor.state.entity_id:
				return
			_combat_status.text = BattleCopy.text(&"fired") % [event.pellet_count, float(event.get("interval_ticks",session.actor.stats.interval_ticks)) / BattleClock.TICKS_PER_SECOND]
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
	touch_overlay.visible = phase == MovementSession.Phase.RUNNING and session.use_touch
	if phase == MovementSession.Phase.PAUSED:
		pause_overlay.show_paused(reason)
	else:
		pause_overlay.dismiss()
	touch_overlay.queue_redraw()

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

func _build_ability_hud() -> void:
	ability_hud.training = session.match_rules == null
	ability_hud.custom_minimum_size = Vector2(284,180)
	add_child(ability_hud)
	add_child(ability_hud.passive_panel)
	ability_hud.release_requested.connect(session.request_ability)
	ability_hud.refill_requested.connect(session.refill_training_ability)
	session.simulation.events.published.connect(ability_hud.on_event)
	session.phase_changed.connect(func(phase: MovementSession.Phase, _reason: StringName) -> void: ability_hud.visible = phase == MovementSession.Phase.RUNNING; ability_hud.passive_panel.visible = ability_hud.visible)

func _layout_ability() -> void:
	ability_hud.set_touch_mode(session.use_touch)
	ability_hud.position = Vector2(size.x-308,140 if session.use_touch else size.y-216)
	ability_hud.passive_panel.position = Vector2(20,size.y-(266 if session.use_touch else 124))
	ability_hud.passive_panel.size = Vector2(256,72)
