extends SceneTree

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/part-references")
	for id: StringName in [&"cannon", &"autocannon", &"scatter", &"light_tracks", &"heavy_tracks", &"scout_wheels"]:
		var texture := HangarPartArtCatalog.texture(id)
		texture.get_image().save_png("res://artifacts/part-references/%s.png" % id)
	quit()
