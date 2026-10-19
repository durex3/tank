extends SceneTree
## Actual Compatibility renderer, 48-pixel sprites on sand/grass/night backgrounds.
var sprites: Array[Sprite3D] = []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(800,480)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.6
	camera.position = Vector3(0,0,10)
	world.add_child(camera)
	camera.make_current()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	world.add_child(environment)
	var index: int = 0
	for art: StringName in ToonFxMaterials.SHEETS:
		for cell: int in range(4):
			var family: StringName = &"water" if art == &"drop" else (&"dust" if art == &"smoke" else (&"guard" if art == &"zap" else &"warm"))
			var sprite: Sprite3D = ToonFxMaterials.create(art,family,cell,0.96)
			sprite.position = Vector3((index%8-3.5)*1.8,(1.5-index/8)*1.8,0)
			world.add_child(sprite)
			sprites.append(sprite)
			index += 1
	for entry: Array in [["sand",Color("c8b78a")],["grass",Color("657d4d")],["night",Color("172238")]]:
		environment.environment.background_color = entry[1]
		for sprite: Sprite3D in sprites: ToonFxMaterials.advance(sprite,0.0)
		await process_frame
		await process_frame
		RenderingServer.force_draw(false)
		var before: Image = root.get_texture().get_image()
		assert(before.save_png("res://artifacts/124-%s-48px.png" % entry[0]) == OK)
		await process_frame
		RenderingServer.force_draw(false)
		assert(before.get_data() == root.get_texture().get_image().get_data(),"No tick must freeze rendered pixels")
		for sprite: Sprite3D in sprites: ToonFxMaterials.advance(sprite,0.85)
		await process_frame
		RenderingServer.force_draw(false)
		var after: Image = root.get_texture().get_image()
		assert(before.get_data() != after.get_data(),"Life change must dissolve rendered pixels")
		assert(after.save_png("res://artifacts/124-%s-eroded.png" % entry[0]) == OK)
	world.free()
	print("TOON RENDER: PASS three backgrounds / 48px / frozen pixels / erosion")
	quit()
