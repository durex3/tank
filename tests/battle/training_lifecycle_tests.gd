extends SceneTree
## Integration cases deliberately wait for real physics frames; no wall-clock rules.

var failures: int = 0
var fired: int = 0
var _screen: Control

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_motion()
	await _test_pause()
	await _test_modal_input()
	await _test_focus_and_keyboard()
	await _test_exit()
	print("TRAINING LIFECYCLE TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_motion() -> void:
	var target := TrainingTarget.new()
	target.position = Vector3(0, 0, -8)
	root.add_child(target)
	target.configure_motion(2.5, 2.0)
	await physics_frame
	await physics_frame
	for frame: int in range(180):
		target.step_motion()
		check(absf(target.position.x) <= 2.501, "moving target remains inside patrol lane")
		check(target.position.y == 0.0 and target.position.z == -8.0, "target stays on configured plane")
		if frame == 74:
			check(is_equal_approx(target.position.x, 2.5), "patrol reaches endpoint at expected tick")
		if frame == 149:
			check(absf(target.position.x) < 0.001, "patrol reverses deterministically")
	var position_before := target.position
	target.state.hp = 0
	target.step_motion()
	check(target.position == position_before, "dead moving target stops")
	target.state.hp = 350
	target.reset_motion()
	check(target.position == target.motion_origin, "rebuild resets patrol to origin")
	# Advance a full meter in a single tick to expose stale Area transforms.
	target.configure_motion(2.5, 60.0)
	target.step_motion()
	var space := target.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(1, 0.78, -6), Vector3(1, 0.78, -10), 4)
	query.collide_with_areas = true
	var collision := space.intersect_ray(query)
	check(not collision.is_empty(), "hurtbox query sees moved position in same tick")
	query.from.x = 0.0
	query.to.x = 0.0
	check(space.intersect_ray(query).is_empty(), "old hurtbox location no longer hits")
	var weapon := load("res://content/weapons/cannon.tres").duplicate() as WeaponDef
	weapon.projectile_speed = 1200.0
	var projectiles := ProjectileSystem.new()
	projectiles.spawn(space, Vector3(1, 0, 0), 0.0, weapon, 1, 1, 1)
	projectiles.step(space, 2)
	check(projectiles.hits.size() == 1, "visible moving target receives swept projectile hit")
	var resolver := DamageResolver.new()
	resolver.resolve_batch(projectiles.hits)
	check(target.state.hp == 230, "moving target loses actual cannon damage")
	target.free()

func _test_pause() -> void:
	_screen = load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(_screen)
	await process_frame
	await physics_frame
	var session: MovementSession = _screen.session
	session.simulation.events.published.connect(_on_event)
	session.set_touch_mode(true)
	var origin := Vector2(110, _screen.size.y - 110)
	session.touch.state.press(0, origin)
	session.touch.state.drag(0, origin + Vector2(64, 0))
	for frame: int in range(12):
		await physics_frame
	check(session.actor.velocity.length() > 0.0, "actor moving before pause")
	var sim := session.simulation
	# Seed a flying shot plus a rebuild timer; neither may advance while paused.
	var shot := sim.projectiles.spawn(session.actor.get_world_3d().direct_space_state,
		Vector3(10, 0, 0), 0.0, sim.weapon, 1, 99, sim.tick)
	var target := sim.targets[0]
	target.state.hp = 0
	target.state.respawn_tick = sim.tick + 5
	var tick_before := sim.tick
	var actor_before := session.actor.position
	var moving_before := sim.targets[1].position
	var shot_before := shot.position
	var range_before := shot.remaining_range
	var ready_before := sim.weapon_controller.next_fire_tick
	session.simulation.events.publish(&"projectile_hit",sim.tick,{"position":Vector3.ZERO})
	var art: AbilitySpriteEffects = session.ability_effects._art
	var flash := art.get_child(art.get_child_count()-1) as Sprite3D
	var flash_scale := flash.scale
	var flash_alpha: float = flash.modulate.a
	session.pause()
	check(_screen.pause_overlay.visible, "pause modal visible")
	check(session.actor.velocity.is_zero_approx(), "pause clears momentum")
	for frame: int in range(15):
		sim.step()
		await physics_frame
	check(is_instance_valid(flash) and flash.scale == flash_scale and flash.modulate.a == flash_alpha, "pause freezes tick-aged imported effect")
	check(sim.tick == tick_before, "both manual and scheduled stepping freeze")
	check(session.actor.position == actor_before, "player position frozen")
	check(sim.targets[1].position == moving_before, "moving target frozen")
	check(shot.position == shot_before and shot.remaining_range == range_before, "projectile and lifetime frozen")
	check(target.state.hp == 0, "rebuild countdown frozen")
	check(not session.touch.state.press(3, origin), "paused touches rejected")
	var old_epoch := sim.session_epoch
	session.resume()
	check(not _screen.pause_overlay.visible, "continue dismisses modal")
	check(sim.session_epoch > old_epoch, "resume invalidates stale controller epoch")
	check(sim.weapon_controller.next_fire_tick == ready_before, "resume preserves cooldown")
	for frame: int in range(8):
		await physics_frame
	check(target.state.hp == target.state.max_hp, "rebuild continues on resumed ticks")
	check(session.actor.position == actor_before, "resume does not retain movement touch")
	check(fired == 0, "resume never turns touch cancellation into fire")
	check(sim.targets[1].position != moving_before, "moving target continues after resume")

func _test_focus_and_keyboard() -> void:
	var session: MovementSession = _screen.session
	session.set_touch_mode(false)
	Input.action_press("move_right")
	for frame: int in range(4):
		await physics_frame
	session.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(session.phase == MovementSession.Phase.PAUSED, "focus loss pauses offline session")
	var tick_before := session.simulation.tick
	session.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for frame: int in range(3):
		await physics_frame
	check(session.simulation.tick == tick_before, "focus return does not auto-resume")
	var position_before := session.actor.position
	session.resume()
	for frame: int in range(6):
		await physics_frame
	check(session.actor.position == position_before, "held pre-pause key blocked until release")
	Input.action_release("move_right")
	await physics_frame
	await physics_frame
	Input.action_press("move_right")
	for frame: int in range(6):
		await physics_frame
	check(session.actor.position.x > position_before.x, "fresh key press resumes control")
	Input.action_release("move_right")
	session.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(session.phase == MovementSession.Phase.PAUSED, "background pauses session")
	session.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(session.phase == MovementSession.Phase.PAUSED, "foreground requires explicit continue")

func _test_exit() -> void:
	var session: MovementSession = _screen.session
	session.stop()
	session.resume()
	check(session.phase == MovementSession.Phase.STOPPED, "stopped session cannot resume")
	root.remove_child(_screen)
	_screen.free()
	await process_frame
	check(root.get_child_count() == 0, "exit releases viewport and session")

func _on_event(event: Dictionary) -> void:
	if event.kind == &"weapon_fired":
		fired += 1

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_modal_input() -> void:
	var session: MovementSession = _screen.session
	session.set_touch_mode(false)
	var count_before := fired
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = root.get_final_transform() * Vector2(640, 360)
	mouse.global_position = mouse.position
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	await process_frame
	session.pause()
	mouse = mouse.duplicate() as InputEventMouseButton
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	await process_frame
	var focused := root.gui_get_focus_owner() as Button
	check(focused != null and focused.text == "Continue training", "pause panel focuses resume button")
	if focused != null:
		mouse = InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = root.get_final_transform() * focused.get_global_rect().get_center()
		mouse.global_position = mouse.position
		mouse.pressed = true
		Input.parse_input_event(mouse)
		Input.flush_buffered_events()
		await process_frame
		mouse = mouse.duplicate() as InputEventMouseButton
		mouse.pressed = false
		Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	for frame: int in range(5):
		await physics_frame
	check(session.phase == MovementSession.Phase.RUNNING, "actual modal click resumes session")
	check(fired == count_before, "resume button release does not become cannon fire")
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	Input.flush_buffered_events()
	await process_frame
	check(session.phase == MovementSession.Phase.PAUSED, "Escape action opens modal")
	session.resume()
