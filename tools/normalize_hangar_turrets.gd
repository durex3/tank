extends SceneTree
## Offline alpha-bound normalization; source generations remain unchanged.

func _initialize() -> void:
	var report: Dictionary = {}
	for id: String in ["cannon", "autocannon", "scatter"]:
		var source := Image.load_from_file("res://assets/generated/parts/aligned-v2/sources/%s.png" % id)
		if source == null or source.detect_alpha() == Image.ALPHA_NONE:
			push_error("Missing transparent turret source: " + id)
			quit(1)
			return
		var bounds: Rect2i = _solid_bounds(source)
		var cropped: Image = source.get_region(bounds)
		var ratio: float = 480.0 / maxf(cropped.get_width(), cropped.get_height())
		cropped.resize(roundi(cropped.get_width() * ratio), roundi(cropped.get_height() * ratio), Image.INTERPOLATE_LANCZOS)
		var normalized := Image.create(512, 512, false, Image.FORMAT_RGBA8)
		normalized.fill(Color.TRANSPARENT)
		var position := Vector2i((512 - cropped.get_width()) / 2, (512 - cropped.get_height()) / 2)
		normalized.blit_rect(cropped, Rect2i(Vector2i.ZERO, cropped.get_size()), position)
		var error: Error = normalized.save_png("res://assets/generated/parts/aligned-v2/%s.png" % id)
		if error != OK:
			quit(1)
			return
		report[id] = {"source_bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "normalized_size": [512, 512], "content_bounds": [position.x, position.y, cropped.get_width(), cropped.get_height()]}
	var output := FileAccess.open("res://artifacts/turret-v2-normalization.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	print("TURRET NORMALIZATION: PASS")
	quit()

func _solid_bounds(image: Image) -> Rect2i:
	# Ignore negligible alpha specks when measuring the object; preserve source pixels.
	var minimum := image.get_size()
	var maximum := Vector2i.ZERO
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a < 0.5: continue
			minimum = minimum.min(Vector2i(x, y))
			maximum = maximum.max(Vector2i(x, y))
	return Rect2i(minimum - Vector2i(4, 4), maximum - minimum + Vector2i(9, 9)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
