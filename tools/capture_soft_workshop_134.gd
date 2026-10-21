extends SceneTree
const CARD: PartCardRenderStyle = preload("res://content/presentation/soft_workshop_cards_v2.tres")
func _initialize() -> void: call_deferred("_run")
func _pair(tank: TankView, candidate: bool) -> void:
	var cannon: Node3D = load("res://presentation/parts/soft_workshop_v2/cannon.tscn" if candidate else "res://presentation/parts/soft_workshop_v1/cannon.tscn").instantiate()
	var hull: Node3D = load("res://presentation/parts/soft_workshop_v2/light_tracks.tscn" if candidate else "res://presentation/parts/soft_workshop_v1/light_tracks.tscn").instantiate()
	TankSurfacePolish.apply(cannon,&"cannon")
	TankSurfacePolish.apply(hull,&"light_tracks")
	tank._replace_child(tank._hull,hull)
	tank._replace_child(tank._turret,cannon)
	tank._turret.position = Vector3(0,.76,0)
func _run() -> void:
	root.size = Vector2i(1280,720)
	var grid := GridContainer.new()
	grid.columns = 2
	root.add_child(grid)
	for angle: float in [0.0,PI,PI/2]:
		for candidate: bool in [false,true]:
			var holder := SubViewportContainer.new()
			holder.custom_minimum_size = Vector2(640,240)
			grid.add_child(holder)
			var viewport := SubViewport.new()
			viewport.size = Vector2i(640,240)
			viewport.own_world_3d = true
			viewport.msaa_3d = Viewport.MSAA_4X
			holder.add_child(viewport)
			var preview := HangarPreview.new()
			viewport.add_child(preview)
			_pair(preview.tank,candidate)
			preview.tank.rotation.y = angle
			var camera := viewport.get_camera_3d()
			camera.size = 2.8
			camera.look_at(Vector3(0,.76,0))
			var label := Label.new()
			label.text = "134 sample" if candidate else "Previous"
			holder.add_child(label)
	for i: int in range(12): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/134-model-comparison.png")==OK)
	grid.free()
	DirAccess.make_dir_recursive_absolute("res://assets/derived/soft-workshop-cards-v2")
	for id: String in ["cannon","light_tracks"]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(512,512)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.own_world_3d = true
		viewport.msaa_3d = Viewport.MSAA_4X
		root.add_child(viewport)
		var preview := HangarPreview.new()
		viewport.add_child(preview)
		preview.tank.hide()
		for child: Node in preview.get_children():
			if child is MeshInstance3D: child.hide()
			if child is WorldEnvironment: child.environment.background_mode = Environment.BG_CLEAR_COLOR
		var part: Node3D = load("res://presentation/parts/soft_workshop_v2/"+id+".tscn").instantiate()
		preview.add_child(part)
		TankSurfacePolish.apply(part,StringName(id))
		var camera := viewport.get_camera_3d()
		camera.size = CARD.camera_size
		camera.position = CARD.camera_position
		camera.look_at(CARD.camera_target)
		for i: int in range(8): await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = viewport.get_texture().get_image()
		assert(is_zero_approx(image.get_pixel(0,0).a),"Card corners must be transparent")
		assert(image.get_used_rect().size.x > 200,"Card must contain visible rendered geometry")
		var bounds: Rect2i = image.get_used_rect()
		assert(bounds.position.x >= 8 and bounds.position.y >= 8 and bounds.end.x <= 504 and bounds.end.y <= 504,"Card geometry must not touch the canvas edge")
		assert(image.save_png("res://assets/derived/soft-workshop-cards-v2/"+id+".png")==OK)
		viewport.free()
	print("SOFT WORKSHOP CAPTURE: PASS")
	quit()
