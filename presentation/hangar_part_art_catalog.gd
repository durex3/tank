extends RefCounted
class_name HangarPartArtCatalog
## Static isolated module concepts, never whole-tank card images or playable models.

const TURRETS: Texture2D = preload("res://assets/generated/parts/turrets-atlas-v1.png")
const CHASSIS: Texture2D = preload("res://assets/generated/parts/chassis-atlas-v1.png")
const ALIGNED_TURRETS: Dictionary = {
	&"cannon": preload("res://assets/generated/parts/aligned-v2/cannon.png"),
	&"autocannon": preload("res://assets/generated/parts/aligned-v2/autocannon.png"),
	&"scatter": preload("res://assets/generated/parts/aligned-v2/scatter.png"),
}
static var _cache: Dictionary = {}
static var _display_cache: Dictionary = {}

## Independent illustrations share a frame; assembly keeps its calibrated source pixels.
static func display_texture(id: StringName) -> Texture2D:
	if _display_cache.has(id):
		return _display_cache[id]
	var source := texture(id)
	if source == null:
		return null
	var image := source.get_image()
	var bounds := image.get_used_rect()
	if not bounds.has_area():
		return source
	var subject := image.get_region(bounds)
	var factor := minf(448.0 / bounds.size.x, 320.0 / bounds.size.y)
	var dimensions := Vector2i(Vector2(bounds.size) * factor)
	subject.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(512, 384, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(subject, Rect2i(Vector2i.ZERO, dimensions), (Vector2i(512, 384) - dimensions) / 2)
	var result := ImageTexture.create_from_image(canvas)
	_display_cache[id] = result
	return result

static func texture(id: StringName) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var entry := PartCatalog.find(id)
	if entry == null or not PartIconFrames.FRAMES.has(str(id)):
		return null
	if ALIGNED_TURRETS.has(id):
		var isolated := AtlasTexture.new()
		isolated.atlas = ALIGNED_TURRETS[id]
		isolated.region = Rect2(0, 0, 512, 512)
		isolated.filter_clip = true
		_cache[id] = isolated
		return isolated
	var frame: Array = PartIconFrames.FRAMES[str(id)]
	var texture := AtlasTexture.new()
	var source: Texture2D = TURRETS if entry.kind == 0 else CHASSIS
	# Isolate pixels before upload so scaled/scroll-clipped drawing cannot sample neighbors.
	var region := Rect2i(frame[0], frame[1], frame[2], frame[3])
	texture.atlas = ImageTexture.create_from_image(source.get_image().get_region(region))
	texture.region = Rect2(0, 0, frame[2], frame[3])
	texture.filter_clip = true
	_cache[id] = texture
	return texture
