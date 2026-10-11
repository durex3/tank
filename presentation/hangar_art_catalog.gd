extends RefCounted
class_name HangarArtCatalog
## Static illustration mapping, independent of authoritative definitions and 3D parts.

const FILES: Dictionary = {
	&"light_tracks": {&"cannon": "res://assets/tanks/cannon-hero-v1.png", &"autocannon": "res://assets/tanks/rapid-hero-v1.png", &"scatter": "res://assets/tanks/scatter-hero-v1.png"},
	&"heavy_tracks": {&"cannon": "res://assets/tanks/heavy-hero-v1.png", &"autocannon": "res://assets/tanks/rapid-heavy-hero-v1.png", &"scatter": "res://assets/tanks/scatter-heavy-hero-v1.png"},
	&"scout_wheels": {&"cannon": "res://assets/generated/hangar/cannon-scout-hero-v1.png", &"autocannon": "res://assets/generated/hangar/autocannon-scout-hero-v1.png", &"scatter": "res://assets/generated/hangar/scatter-scout-hero-v1.png"},
}

static var _cache: Dictionary = {}

static func texture(weapon: StringName, chassis: StringName) -> Texture2D:
	if not FILES.has(chassis) or not FILES[chassis].has(weapon):
		return null
	var path: String = FILES[chassis][weapon]
	if _cache.has(path): return _cache[path]
	var original := (load(path) as Texture2D).get_image()
	var bounds := original.get_used_rect()
	var cropped := original.get_region(bounds)
	var scale: float = 920.0 / float(maxi(cropped.get_width(), cropped.get_height()))
	cropped.resize(maxi(1, roundi(cropped.get_width() * scale)), maxi(1, roundi(cropped.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, cropped.get_size()), Vector2i((1024 - cropped.get_width()) / 2, (1024 - cropped.get_height()) / 2))
	_cache[path] = ImageTexture.create_from_image(canvas)
	return _cache[path]
