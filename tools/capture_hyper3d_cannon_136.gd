extends "res://tools/normalize_part_sizes.gd"
## Experimental-only renders. Does not change production catalog or profiles.
const CANDIDATE := "res://presentation/parts/hyper3d_cannon_study_v1/cannon.tscn"
const ART := "res://artifacts/136-"
func _run() -> void:
	root.size = Vector2i(1220, 700)
	var grid := GridContainer.new()
	grid.columns = 3
	root.add_child(grid)
	for kind: String in ["source", "recolor", "adapted"]:
		for angle: float in [0.0, PI/2, PI]:
			var viewport := _viewport(grid, Vector2i(400,220))
			var preview := HangarPreview.new()
			viewport.add_child(preview)
			preview.tank.hide()
			for node: Node in preview.get_children():
				if node is MeshInstance3D: node.hide()
			var part: Node3D
			if kind == "source":
				var doc := GLTFDocument.new()
				var state := GLTFState.new()
				assert(doc.append_from_file("/Users/liugelong/Downloads/487d6b33-e68a-4f2b-ae8f-654fd32c2452/base_basic_shaded.glb",state)==OK)
				part = doc.generate_scene(state)
				part.rotation.y = PI
			else:
				part = load(CANDIDATE if kind == "adapted" else "res://assets/derived/hyper3d-cannon-study-v1/cannon_native.glb").instantiate()
			preview.add_child(part)
			var box := _bounds(part)
			var center := box.get_center()
			var camera := viewport.get_camera_3d()
			camera.size = maxf(box.size.x,maxf(box.size.y,box.size.z))*1.15
			camera.position = center+Vector3(-3,2.6,-4).rotated(Vector3.UP,angle)*2
			camera.look_at(center)
			var label := Label.new()
			label.text = kind+" / "+str(roundi(rad_to_deg(angle)))
			viewport.get_parent().add_child(label)
	await _frames()
	assert(root.get_texture().get_image().save_png(ART+"shape-comparison.png")==OK)
	grid.free()
	root.size = Vector2i(1280,720)
	grid = GridContainer.new()
	grid.columns = 2
	root.add_child(grid)
	var candidate_preview: HangarPreview
	for candidate: bool in [false,true]:
		var viewport := _viewport(grid,Vector2i(640,720))
		var preview := HangarPreview.new()
		viewport.add_child(preview)
		if candidate:
			candidate_preview=preview
			var part: Node3D=load(CANDIDATE).instantiate()
			preview.tank._replace_child(preview.tank._turret,part)
			TankSurfacePolish.apply(part,&"cannon")
			_validate(part)
		var camera:=viewport.get_camera_3d()
		camera.size=3.1
		camera.look_at(Vector3(0,.85,0))
		var label:=Label.new()
		label.text="Candidate 136" if candidate else "Current 135"
		viewport.get_parent().add_child(label)
	await _frames()
	assert(root.get_texture().get_image().save_png(ART+"assembled.png")==OK)
	var part:=candidate_preview.tank._turret.get_child(0) as Node3D
	var pivot:=part.find_child("RecoilPivot",true,false) as Node3D
	var marker:=part.get_node("Muzzle") as Marker3D
	var visual:=part.find_child("VisualMuzzle",true,false) as Node3D
	var before:=marker.global_transform
	var start:=visual.global_position
	var recoil:=TankRecoil.new()
	recoil.bind(part,&"cannon")
	recoil.fire(1,true)
	recoil.advance(2)
	assert(pivot.position.length()>.1)
	assert(start.distance_to(visual.global_position)>.1)
	assert(marker.global_transform.is_equal_approx(before))
	var freeze:=pivot.transform
	recoil.advance(2)
	assert(pivot.transform.is_equal_approx(freeze))
	await _frames()
	assert(root.get_texture().get_image().save_png(ART+"recoil.png")==OK)
	recoil.advance(40)
	assert(pivot.position.is_zero_approx())
	grid.free()
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(512,512)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.msaa_3d=Viewport.MSAA_4X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview:=HangarPreview.new()
	viewport.add_child(preview)
	preview.tank.hide()
	for node: Node in preview.get_children():
		if node is MeshInstance3D:node.hide()
		if node is WorldEnvironment:node.environment.background_mode=Environment.BG_CLEAR_COLOR
	part=load(CANDIDATE).instantiate()
	preview.add_child(part)
	TankSurfacePolish.apply(part,&"cannon")
	var camera:=viewport.get_camera_3d()
	camera.size=2.5
	camera.position=Vector3(-3,2.1,-4)
	camera.look_at(Vector3(0,.40,-.18))
	await _frames()
	var picture:=viewport.get_texture().get_image()
	assert(is_zero_approx(picture.get_pixel(0,0).a))
	var used:=picture.get_used_rect()
	assert(used.position.x>=8 and used.position.y>=8 and used.end.x<=504 and used.end.y<=504)
	assert(picture.save_png(ART+"card-512.png")==OK)
	picture.resize(128,128,Image.INTERPOLATE_LANCZOS)
	assert(picture.save_png(ART+"card-128.png")==OK)
	print("136 CANDIDATE PASS: envelope, circular barrel, rigid recoil, immutable authority, frozen tick, transparent cards")
	quit()
func _viewport(grid: GridContainer,size: Vector2i) -> SubViewport:
	var holder:=SubViewportContainer.new()
	holder.custom_minimum_size=Vector2(size)
	grid.add_child(holder)
	var viewport:=SubViewport.new()
	viewport.size=size
	viewport.own_world_3d=true
	viewport.msaa_3d=Viewport.MSAA_4X
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	return viewport
func _frames() -> void:
	for i: int in range(12):await process_frame
	await RenderingServer.frame_post_draw
func _validate(part: Node3D) -> void:
	assert(TankPartCatalog.validate_part(part,&"Muzzle",Vector3(0,.02,-1.05)).is_empty())
	var actual:=_bounds(part)
	var target: AABB=STYLE.turret_bounds
	print("136 BOUNDS ",actual," expected ",target)
	assert((actual.position-target.position).length()<.0002 and (actual.size-target.size).length()<.0002)
	var barrel:=part.find_child("Barrel",true,false) as MeshInstance3D
	assert(barrel!=null)
	var size:=barrel.get_aabb().size
	assert(absf(size.x-size.y)<.0001,"Barrel cross-section must remain circular")
