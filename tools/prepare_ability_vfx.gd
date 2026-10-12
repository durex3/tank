extends SceneTree
## Deterministic import preparation: isolate atlas cells, preserve alpha and normalize canvas.

func _initialize() -> void:
	var source := Image.load_from_file("res://assets/generated/vfx/abilities-v1/atlas-v2.png")
	assert(source != null and source.get_format() == Image.FORMAT_RGBA8)
	var names: Array[String] = ["smoke","muzzle","impact","shockwave"]
	var report: Dictionary = {"size":str(source.get_size()),"sprites":{}}
	var cell: Vector2i = source.get_size()/2
	for i: int in range(4):
		var region := Rect2i(Vector2i(i%2,i/2)*cell,cell)
		var isolated: Image = source.get_region(region)
		var used: Rect2i = _visible_bounds(isolated)
		print(names[i]," alpha bounds ",used," cell ",cell)
		assert(used.has_area())
		assert(used.position.x > 8 and used.position.y > 8 and used.end.x < cell.x-8 and used.end.y < cell.y-8,"Effect must not touch cell boundary")
		var sprite: Image = isolated.get_region(used)
		var scale_factor: float = 464.0/maxi(sprite.get_width(),sprite.get_height())
		sprite.resize(roundi(sprite.get_width()*scale_factor),roundi(sprite.get_height()*scale_factor),Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(512,512,false,Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blit_rect(sprite,Rect2i(Vector2i.ZERO,sprite.get_size()),(Vector2i(512,512)-sprite.get_size())/2)
		assert(canvas.save_png("res://assets/generated/vfx/abilities-v1/"+names[i]+".png") == OK)
		report.sprites[names[i]] = {"cell":str(region),"alpha_bounds":str(used),"canvas":"512x512 RGBA"}
	var file := FileAccess.open("res://artifacts/ability-vfx-preparation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("ABILITY VFX PREPARATION: PASS ",JSON.stringify(report))
	quit()

func _visible_bounds(image: Image) -> Rect2i:
	# Ignore sub-1% alpha numerical wisps for framing, retaining original alpha inside the crop.
	var low := image.get_size()
	var high := Vector2i.ZERO
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x,y).a >= 0.01:
				low = Vector2i(mini(low.x,x),mini(low.y,y))
				high = Vector2i(maxi(high.x,x),maxi(high.y,y))
	return Rect2i(low,high-low+Vector2i.ONE)
