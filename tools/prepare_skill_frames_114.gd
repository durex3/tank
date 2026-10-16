extends SceneTree
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/generated/vfx/skills-v2/source-sheet.png")
	assert(source != null)
	print("Generated sheet ",source.get_size()," alpha: ",source.detect_alpha())
	var names: Array[String] = ["lightning","armor","dust","reload"]
	for row: int in range(4):
		for column: int in range(4):
			var start := Vector2i(roundi(column*source.get_width()/4.0),roundi(row*source.get_height()/4.0))
			var end := Vector2i(roundi((column+1)*source.get_width()/4.0),roundi((row+1)*source.get_height()/4.0))
			var frame := source.get_region(Rect2i(start,end-start))
			frame.resize(232,232,Image.INTERPOLATE_LANCZOS)
			var canvas := Image.create(256,256,false,Image.FORMAT_RGBA8)
			canvas.fill(Color.TRANSPARENT)
			canvas.blit_rect(frame,Rect2i(0,0,232,232),Vector2i(12,12))
			assert(canvas.save_png("res://assets/generated/vfx/skills-v2/%s-%d.png" % [names[row],column]) == OK)
	quit()
