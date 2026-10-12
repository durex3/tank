extends SceneTree

func _initialize() -> void:
	var directory := DirAccess.open("res://artifacts/concept-candidates/hangar-v2")
	for file: String in directory.get_files():
		if not file.ends_with(".png"): continue
		var image := Image.load_from_file("res://artifacts/concept-candidates/hangar-v2/" + file)
		print(file, " ", image.get_size(), " alpha=", image.detect_alpha(), " corner=", image.get_pixel(0,0).a, " edge=", image.get_pixel(0,image.get_height()/2).a)
	quit()
