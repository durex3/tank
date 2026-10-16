extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1200,600)
	var grid := GridContainer.new()
	grid.columns = 4
	root.add_child(grid)
	for mode: int in range(4):
		var box := SubViewportContainer.new()
		box.custom_minimum_size = Vector2(296,580)
		grid.add_child(box)
		var vp := SubViewport.new()
		vp.size = Vector2i(296,580)
		vp.own_world_3d = true
		box.add_child(vp)
		var studio := HangarPreview.new()
		vp.add_child(studio)
		studio.tank.hide()
		for node: Node in studio.get_children():
			if node is MeshInstance3D: node.hide()
			if node is DirectionalLight3D:
				node.shadow_bias = [0.1,0.1,0.1,0.5][mode]
				node.shadow_normal_bias = [1.0,0.0,2.0,0.0][mode]
		var part := (TankPartCatalog.CHASSIS[&"scout_wheels"] as PackedScene).instantiate() as Node3D
		studio.add_child(part)
		TankSurfacePolish.apply(part, &"scout_wheels")
		if false:
			for mesh: MeshInstance3D in part.find_children("*", "MeshInstance3D", true, false):
				for surface: int in range(mesh.mesh.get_surface_count()):
					var mat := mesh.get_active_material(surface) as ShaderMaterial
					if mat != null: mat.set_shader_parameter("has_normal_map", false)
		var camera := vp.get_camera_3d()
		camera.size = 2.4
		camera.position = Vector3(-3,2.2,-4)
		camera.look_at(Vector3(0,.5,0))
		var label := Label.new()
		label.text = ["Normal bias 1", "Normal bias 0", "Normal bias 2", "Bias .5 normal 0"][mode]
		box.add_child(label)
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/103-shadow-diagnostic.png")
	quit()
