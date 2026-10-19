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
	var model := Node3D.new()
	var parts: bool = "--parts" in OS.get_cmdline_user_args()
	if parts:
		model.add_child(load("res://presentation/parts/rodin_v1/light_tracks.tscn").instantiate())
		var turret := load("res://presentation/parts/rodin_v1/cannon.tscn").instantiate() as Node3D
		turret.position.y = 0.76
		model.add_child(turret)
	else:
		model.add_child(load("res://assets/imported/rodin-v1/tank_pbr.glb").instantiate())
	world.add_child(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.8 if parts else 2.6
	world.add_child(camera)
	for i: int in range(4):
		var angle: float = PI * 0.25 + i * PI * 0.5
		camera.position = Vector3(sin(angle) * 3.0, 1.8, cos(angle) * 3.0)
		camera.look_at(Vector3(0, 0.6, 0) if parts else Vector3.ZERO)
		for frame: int in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/rodin-%s-%d.png" % ["parts" if parts else "source", i])
	print("RODIN SOURCE CAPTURE PASS")
	quit()
