extends SceneTree
## Isolated art sample. Does not change the runtime catalog or authoritative sockets.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1100, 900)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var hull := load("res://assets/derived/mechanical-sample-v1/scout_wheels.glb").instantiate() as Node3D
	var turret := load("res://assets/derived/mechanical-sample-v1/cannon.glb").instantiate() as Node3D
	world.add_child(hull)
	world.add_child(turret)
	turret.position.y = 0.885
	for name: String in ["WheelLeftFront", "WheelLeftRear", "WheelRightFront", "WheelRightRear"]:
		assert(hull.find_child(name, true, false) is Node3D)
	assert(turret.find_child("RecoilPivot", true, false) != null)
	assert(turret.find_child("VisualMuzzle", true, false) != null)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("292735")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e3e7ed")
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	for data: Vector3 in [Vector3(-45,-30,1.1),Vector3(-25,120,0.5)]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(data.x,data.y,0)
		light.light_energy = data.z
		world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.8
	world.add_child(camera)
	for name: String in ["front", "rear"]:
		camera.position = Vector3(-3,2.4,-4) if name == "front" else Vector3(3,2.4,4)
		camera.look_at(Vector3(0,0.72,0))
		for i: int in range(8): await process_frame
		await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png("res://assets/derived/mechanical-sample-v1/godot-"+name+".png") == OK)
	print("MECHANICAL SAMPLE IMPORT AND RIG NODES: PASS")
	world.free()
	viewport.queue_free()
	for i: int in range(3): await process_frame
	quit()
