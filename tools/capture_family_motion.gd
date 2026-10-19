extends SceneTree
## Standalone inspection; no production catalog changes.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(960, 720)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.20, 0.23, 0.28)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.85, 0.89, 1.0)
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.0
	world.add_child(light)
	var model := TankView.new()
	world.add_child(model)
	var args := OS.get_cmdline_user_args()
	var weapon: StringName = StringName(args[0]) if args.size() > 0 else &"autocannon"
	var chassis: StringName = StringName(args[1]) if args.size() > 1 else &"heavy_tracks"
	assert(model.configure_parts(weapon, chassis).is_empty())
	var state := TankState.new()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.3
	world.add_child(camera)
	camera.position = Vector3(-3, 1.8, -3)
	camera.look_at(Vector3(0, 0.5, 0))
	DirAccess.make_dir_recursive_absolute("res://artifacts/family-motion-frames")
	for tick: int in range(24):
		if tick < 32:
			state.position.z -= 0.012
		elif tick < 56:
			state.position.z += 0.012
		elif tick < 80:
			state.body_yaw += 0.012
		if tick == 2:
			model.on_event({"kind": &"weapon_fired", "source_id": 0, "weapon": weapon, "tick": tick})
		model.present(state)
		model.advance_visual_tick(tick)
		for frame: int in range(2): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/family-motion-frames/%s-%s-%03d.png" % [weapon, chassis, tick])
	print("TRACK SEQUENCE CAPTURE PASS")
	quit()
