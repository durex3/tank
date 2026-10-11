extends RefCounted
class_name HangarPartArtCatalog
## Static isolated module concepts, never whole-tank card images or playable models.

const TURRETS: Texture2D = preload("res://assets/generated/parts/turrets-atlas-v1.png")
const CHASSIS: Texture2D = preload("res://assets/generated/parts/chassis-atlas-v1.png")
static var _cache: Dictionary = {}

static func texture(id: StringName) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var entry := PartCatalog.find(id)
	if entry == null or not PartIconFrames.FRAMES.has(str(id)):
		return null
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
