extends SceneTree
## Isolated real-render coverage at the production camera scale; complements training captures.
var failures: int = 0
var metrics: Array[Dictionary] = []
func _initialize() -> void: call_deferred("_run")
func _draw() -> Image:
	await process_frame
	RenderingServer.force_draw(false)
	return root.get_texture().get_image()
func _run() -> void:
	root.size = Vector2i(1280,720)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = preload("res://content/camera/fixed_arena.tres").orthographic_size
	camera.position = preload("res://content/camera/fixed_arena.tres").offset
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	world.add_child(environment)
	for background: Array in [["sand",Color("c8b78a")],["grass",Color("657d4d")],["night",Color("172238")]]:
		environment.environment.background_color = background[1]
		await process_frame
		for kind: String in ["cannon","storm","scatter","bubble_lob","bubble_field"]:
			var blank: Image = await _draw()
			var effect: Node3D
			if kind == "cannon":
				var signature := AbilitySignatureEffects.new()
				world.add_child(signature)
				signature.on_event({"kind":&"ability_fired","ability":&"breach","source_id":1,"tick":10,"position":Vector3(0,0.78,3),"end":Vector3(0,0.78,-3)})
				signature.on_event({"kind":&"tick","tick":16})
				effect = signature
			else:
				var view := CombatView.new()
				view.set_process(false)
				view.projectiles = ProjectileSystem.new()
				var shot := ProjectileState.new()
				shot.projectile_id = 1
				shot.spawn_tick = 0
				shot.position = Vector3(0,0.78,0)
				shot.direction = Vector3.FORWARD
				shot.weapon_id = &"scatter" if kind == "scatter" else &"autocannon"
				shot.storm_round = kind == "storm"
				if kind.begins_with("bubble"):
					shot.kind = StringName(kind)
					shot.radius = 2.2 if kind == "bubble_field" else 0.45
					shot.arc_ticks = 36
					shot.lifetime_ticks = 240 if kind == "bubble_field" else 0
				view.projectiles.active.append(shot)
				world.add_child(view)
				view.on_event({"kind":&"tick","tick":18})
				view._process(0)
				effect = view
			var visible: Image = await _draw()
			var pixels: int = 0
			for y: int in range(170,550):
				for x: int in range(380,900):
					var a: Color = blank.get_pixel(x,y)
					var b: Color = visible.get_pixel(x,y)
					if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))) > 0.08: pixels += 1
			var minimum: int = 300 if kind == "cannon" else 90 if kind in ["storm","scatter"] else 600
			metrics.append({"background":background[0],"kind":kind,"contrasting_pixels":pixels,"minimum":minimum})
			if pixels < minimum:
				failures += 1
				push_error("Insufficient coverage: %s %s %d < %d" % [background[0],kind,pixels,minimum])
			var frozen: Image = await _draw()
			if visible.get_data() != frozen.get_data():
				failures += 1
				push_error("No-tick rendering drift: "+kind)
			visible.save_png("res://artifacts/131-readability-%s-%s.png" % [background[0],kind])
			effect.free()
			await process_frame
	var file := FileAccess.open("res://artifacts/131-readability.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t"))
	world.free()
	print("READABILITY RENDER: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
