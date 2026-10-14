extends SceneTree
## Deterministic framing only; originals and generated cutouts remain untouched.

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/derived/model-reference-cards-v1")
	for id: String in ["cannon", "autocannon", "scatter", "bubble_cannon", "light_tracks", "heavy_tracks", "scout_wheels"]:
		var source := Image.load_from_file("res://assets/generated/model-reference-cards-v1/%s.png" % id)
		assert(source != null and source.detect_alpha() != Image.ALPHA_NONE)
		assert(source.get_pixel(0, 0).a < 0.01, "transparent corner required")
		# Generated cutouts can contain near-transparent pixels far from the solid object.
		var first := Vector2i(source.get_width(), source.get_height())
		var last := Vector2i.ZERO
		for y: int in range(source.get_height()):
			for x: int in range(source.get_width()):
				if source.get_pixel(x, y).a < 0.1:
					continue
				first = first.min(Vector2i(x, y))
				last = last.max(Vector2i(x, y))
		var bounds := Rect2i(first, last - first + Vector2i.ONE)
		assert(bounds.has_area())
		var subject: Image = source.get_region(bounds)
		var factor: float = minf(480.0 / bounds.size.x, 400.0 / bounds.size.y)
		var dimensions := Vector2i(Vector2(bounds.size) * factor)
		subject.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(512, 512, false, Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blit_rect(subject, Rect2i(Vector2i.ZERO, dimensions), (Vector2i(512, 512) - dimensions) / 2)
		assert(canvas.save_png("res://assets/derived/model-reference-cards-v1/%s.png" % id) == OK)
		print(id, " bounds=", bounds, " normalized=", dimensions)
	print("REFERENCE CARDS: PASS")
	quit()
