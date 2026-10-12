extends SceneTree

func _initialize() -> void:
	for label: String in ["bubble","pop"]:
		var image := Image.load_from_file("res://assets/generated/vfx/bubble-v2/"+label+"-source.png")
		assert(image != null and image.detect_alpha() != Image.ALPHA_NONE)
		image.resize(512,512,Image.INTERPOLATE_LANCZOS)
		assert(image.save_png("res://assets/generated/vfx/bubble-v2/"+label+".png") == OK)
	print("BUBBLE ART: PASS")
	quit()
