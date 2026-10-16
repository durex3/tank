extends Node3D
class_name MovementSession
## Application orchestration: owns input sampling and simulation lifecycle.

signal phase_changed(phase: Phase, reason: StringName)

enum Phase { RUNNING, PAUSED, FINISHED, STOPPED }

const ACTOR := preload("res://battle/actors/tank_actor.tscn")
const ARENA := preload("res://session/graybox_arena.gd")
var match_rules: MatchRules
var weapon: WeaponDef = preload("res://content/weapons/cannon.tres")
var chassis: ChassisDef = preload("res://content/chassis/light_tracks.tres")
var simulation := BattleSimulation.new()
var touch := TouchInputSource.new()
var desktop := DesktopInputSource.new()
var rig := CameraRig.new()
var actor: TankActor
var _view := TankView.new()
var combat_view := CombatView.new()
var ability_effects := AbilityEffects.new()
var sparring: SparringSession
var use_touch: bool = false
var mouse_viewport_position: Vector2 = Vector2.ZERO
var phase: Phase = Phase.RUNNING
var enabled: bool:
	get:
		return phase == Phase.RUNNING

var can_control: bool:
	get:
		return enabled and actor != null and actor.health.hp > 0

func _ready() -> void:
	use_touch = OS.has_feature("android") or OS.has_feature("ios")
	var world := Node3D.new()
	world.set_script(ARENA)
	add_child(world)
	actor = ACTOR.instantiate() as TankActor
	add_child(actor)
	actor.configure(LoadoutResolver.resolve(weapon, chassis), chassis.acceleration)
	_view.weapon_id = weapon.id
	_view.chassis_id = chassis.id
	_view.entity_id = actor.state.entity_id
	simulation.weapon = weapon
	simulation.abilities.training = match_rules == null
	simulation.abilities.register(actor,weapon.id,chassis.id)
	touch.set_continuous_fire(weapon.continuous_fire)
	desktop.continuous_fire = weapon.continuous_fire
	actor.add_child(_view)
	add_child(simulation)
	simulation.actor = actor
	simulation.snapshot_ready.connect(_present_player)
	simulation.events.published.connect(_view.on_event)
	add_child(touch)
	add_child(desktop)
	touch.set_enabled(use_touch)
	desktop.set_enabled(not use_touch)
	add_child(rig)
	add_child(combat_view)
	add_child(ability_effects)
	simulation.events.published.connect(_present_effect_event)
	combat_view.projectiles = simulation.projectiles
	combat_view.ability_art_enabled = true
	if match_rules == null:
		_create_targets()
	_attach_player_health()
	simulation.events.published.connect(_on_life_event)
	_create_lighting()
	if match_rules != null:
		_start_match()

func _present_effect_event(event: Dictionary) -> void:
	var display_event: Dictionary = event
	var view: TankView = _view if event.get("source_id", -1) == _view.entity_id else null
	if view == null and is_instance_valid(sparring) and event.get("source_id", -1) == sparring._view.entity_id:
		view = sparring._view
	if view != null:
		if event.kind == &"weapon_fired" or (event.kind == &"ability_fired" and event.get("ability", &"") == &"breach"):
			# Rival views subscribe after this bridge; consume the idempotent fact first.
			view.on_event(event)
			display_event = event.duplicate()
			display_event.authoritative_muzzle_position = event.position
			display_event.visual_muzzle_position = view.visual_muzzle_position()
			display_event.barrel_index = view.active_barrel_index()
			display_event.position = view.visual_muzzle_position()
		elif event.kind == &"ability_state" and event.get("phase", &"") == &"breach":
			display_event = event.duplicate()
			display_event.visual_muzzle_position = view.visual_muzzle_position()
	ability_effects.on_event(display_event)
	combat_view.on_event(display_event)

func _create_lighting() -> void:
	var style := preload("res://content/presentation/training_view.tres") as TrainingViewStyle
	var light := DirectionalLight3D.new()
	light.rotation_degrees = style.key_rotation
	light.light_color = style.key_color
	light.light_energy = style.key_energy
	light.shadow_enabled = true
	light.shadow_normal_bias = style.shadow_normal_bias
	light.shadow_bias = style.shadow_bias
	light.shadow_blur = style.shadow_blur
	light.directional_shadow_max_distance = style.shadow_distance
	add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = style.fill_rotation
	fill.light_color = style.fill_color
	fill.light_energy = style.fill_energy
	add_child(fill)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = style.background_color
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = style.ambient_color
	environment.environment.ambient_light_energy = style.ambient_energy
	add_child(environment)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var command: PlayerCommand
	if use_touch:
		command = PlanarInput.map_command(touch.sample(simulation.tick + 1), rig.horizontal_right(), rig.horizontal_forward())
	else:
		var point := rig.ground_point(mouse_viewport_position)
		desktop.aim_distance_cm = clampi(roundi(Vector2(point.x-actor.position.x,point.z-actor.position.z).length()*100),150,1600)
		desktop.aim_direction = Vector2(point.x - actor.position.x, point.z - actor.position.z).normalized()
		command = desktop.sample(simulation.tick + 1)
		# Mouse aim is already in world space. Only keyboard movement needs mapping.
		var move := PlanarInput.to_world(Vector2(command.move_x, command.move_z) / 127.0, rig.horizontal_right(), rig.horizontal_forward())
		command.move_x = roundi(move.x * 127.0)
		command.move_z = roundi(move.y * 127.0)
	if sparring != null:
		sparring.sample_next_tick()
	simulation.enqueue_command(command)
	simulation.step()
	rig.follow(actor.position, delta)

func stop() -> void:
	_view.reset_visual_motion()
	if sparring != null:
		sparring.reset_visual_motion()
	phase = Phase.STOPPED
	_suspend_inputs()
	simulation.abilities.clear(simulation.projectiles)
	ability_effects.clear()
	simulation.set_paused(true)
	combat_view.set_paused(true)
	phase_changed.emit(phase, &"exit")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_node_ready():
			pause(&"focus_lost")

func set_touch_mode(value: bool) -> void:
	touch.set_enabled(can_control and value)
	desktop.set_enabled(can_control and not value)
	simulation.clear_command()
	# Device handoff gets a new controller epoch while preserving weapon cooldown.
	var epoch := simulation.replace_controller()
	touch.session_epoch = epoch
	desktop.session_epoch = epoch
	use_touch = value

func _create_targets() -> void:
	var rules := simulation.training_rules
	var style := preload("res://content/presentation/training_view.tres") as TrainingViewStyle
	var errors := rules.validate()
	if not errors.is_empty():
		push_error("Invalid training content: " + "; ".join(errors))
		return
	for index: int in range(rules.target_hp.size()):
		var target := TrainingTarget.new()
		target.state.entity_id = 100 + index
		target.state.max_hp = rules.target_hp[index]
		target.state.hp = rules.target_hp[index]
		target.position = rules.target_positions[index]
		add_child(target)
		target.configure_motion(rules.target_motion_extents[index], rules.target_motion_speeds[index])
		simulation.targets.append(target)
		var view := TrainingTargetView.new()
		view.target_id = target.state.entity_id
		view.chassis_id = style.target_chassis[index % style.target_chassis.size()]
		view.caption = style.target_captions[index % style.target_captions.size()]
		target.add_child(view)
		simulation.events.published.connect(view.on_event)
		view.show_health(target.state.hp, target.state.max_hp)
		view.set_moving(target.motion_extent > 0.0)

func pause(reason: StringName = &"manual") -> void:
	if phase != Phase.RUNNING:
		return
	phase = Phase.PAUSED
	_suspend_inputs()
	simulation.set_paused(true)
	combat_view.set_paused(true)
	phase_changed.emit(phase, reason)

func resume() -> void:
	if phase != Phase.PAUSED:
		return
	# All stale touch ownership and request IDs are discarded before the next tick.
	var epoch := simulation.replace_controller()
	touch.session_epoch = epoch
	desktop.session_epoch = epoch
	touch.set_enabled(actor.health.hp > 0 and use_touch)
	desktop.set_enabled(actor.health.hp > 0 and not use_touch)
	if sparring != null:
		sparring.reset_intent()
	simulation.set_paused(false)
	combat_view.set_paused(false)
	phase = Phase.RUNNING
	phase_changed.emit(phase, &"resume")

func _suspend_inputs() -> void:
	touch.set_enabled(false)
	desktop.set_enabled(false)

func configure_loadout(weapon_id: StringName, chassis_id: StringName, weapon_level: int = 1, chassis_level: int = 1) -> String:
	if is_inside_tree():
		return "Training loadout is immutable after session start"
	var next_weapon := PartGrowth.weapon(weapon_id, weapon_level)
	var next_chassis := PartGrowth.chassis(chassis_id, chassis_level)
	if next_weapon == null or next_chassis == null:
		return "Unknown loadout ID"
	if not LoadoutResolver.can_save(next_weapon, next_chassis):
		return "Invalid training loadout"
	weapon = next_weapon
	chassis = next_chassis
	return ""

func start_sparring() -> String:
	if not enabled or not is_node_ready():
		return "Training session is not running"
	if sparring != null:
		return "Sparring is already active"
	var rules := preload("res://content/training/sparring.tres") as SparringRules
	var errors := rules.validate()
	if not errors.is_empty():
		return "; ".join(errors)
	var spawn := TrainingLives.safe_spawn(actor.get_world_3d().direct_space_state, rules.spawn)
	if not spawn.is_finite():
		return "Rival spawn lane is occupied"
	sparring = SparringSession.new()
	sparring.spawn_point = spawn
	sparring.simulation = simulation
	sparring.player = actor
	add_child(sparring)
	return ""

func _attach_player_health() -> void:
	var health := TankHealthView.new()
	health.entity_id = actor.state.entity_id
	health.visual = _view
	actor.add_child(health)
	health.show_health(actor.health.hp, actor.health.max_hp)
	simulation.events.published.connect(health.on_event)

func _on_life_event(event: Dictionary) -> void:
	if event.kind != &"entity_died" and event.kind != &"entity_respawned":
		return
	if event.target_id == actor.state.entity_id:
		_suspend_inputs()
		var epoch := simulation.replace_controller()
		touch.session_epoch = epoch
		desktop.session_epoch = epoch
		touch.set_enabled(can_control and use_touch)
		desktop.set_enabled(can_control and not use_touch)
	if sparring != null and event.target_id in [actor.state.entity_id, 2]:
		sparring.reset_intent()

func configure_match(rules: MatchRules) -> String:
	if is_inside_tree() or rules == null:
		return "Match configuration requires a new session"
	var errors := rules.validate()
	if not errors.is_empty() or rules.team_size != 1:
		return "This offline slice supports one tank per team"
	match_rules = rules.duplicate(true) as MatchRules
	return ""

func _start_match() -> void:
	var error := start_sparring()
	if not error.is_empty():
		stop()
		push_error(error)
		return
	var tuning := sparring.rules.duplicate(true) as SparringRules
	tuning.rebuild_ticks = match_rules.respawn_ticks
	tuning.protection_ticks = match_rules.protection_ticks
	simulation.lives.tuning = tuning
	actor.health.is_training = false
	sparring.rival.health.is_training = false
	var runtime := MatchRuntime.new()
	var match_id := "offline_%d_%d" % [Time.get_ticks_usec(), get_instance_id()]
	error = runtime.configure(match_id, match_rules, {actor.state.entity_id: 0, sparring.rival.state.entity_id: 1})
	if not error.is_empty():
		stop()
		push_error(error)
		return
	simulation.match_runtime = runtime
	simulation.events.published.connect(_on_match_event)

func _on_match_event(event: Dictionary) -> void:
	if event.kind != &"match_finished":
		return
	simulation.abilities.clear(simulation.projectiles)
	ability_effects.clear()
	phase = Phase.FINISHED
	_suspend_inputs()
	var epoch := simulation.replace_controller()
	touch.session_epoch = epoch
	desktop.session_epoch = epoch
	simulation.set_paused(true)
	combat_view.set_paused(true)
	phase_changed.emit(phase, &"match_finished")

func refill_training_ability() -> bool:
	return enabled and match_rules == null and simulation.abilities.refill(actor)

func request_ability() -> void:
	if not can_control: return
	if use_touch: touch.request_ability()
	else: desktop.request_ability()

func _present_player(state: TankState) -> void:
	_view.present(state)
	_view.advance_visual_tick(simulation.tick)
