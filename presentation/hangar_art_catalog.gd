extends RefCounted
class_name HangarArtCatalog
## Static appearance assembled from the exact same isolated module art as the cards.

const COMPOSITION: HangarCompositionStyle = preload("res://content/presentation/hangar_composition.tres")


static var _cache: Dictionary = {}

static func texture(weapon: StringName, chassis: StringName) -> Texture2D:
	if not COMPOSITION.chassis_mounts.has(chassis) or not COMPOSITION.turret_mounts.has(weapon): return null
	var key: String = "%s/%s" % [weapon, chassis]
	if _cache.has(key): return _cache[key]
	var hull_source := HangarPartArtCatalog.texture(chassis)
	var turret_source := HangarPartArtCatalog.texture(weapon)
	if hull_source == null or turret_source == null: return null
	var hull := hull_source.get_image().duplicate() as Image
	var turret := turret_source.get_image().duplicate() as Image
	# Chassis cards face right, turret cards face left. Mirror the symmetric hull only.
	hull.flip_x()
	_resize_width(hull, COMPOSITION.chassis_width)
	_resize_width(turret, COMPOSITION.turret_width)
	_recess_turret_base(turret, weapon)
	var canvas := Image.create(COMPOSITION.canvas_size, COMPOSITION.canvas_size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	var hull_position := Vector2i((COMPOSITION.canvas_size - hull.get_width()) / 2, COMPOSITION.chassis_bottom - hull.get_height())
	var hull_anchor: Vector2 = COMPOSITION.chassis_mounts[chassis]
	var turret_anchor: Vector2 = COMPOSITION.turret_mounts[weapon]
	var mount: Vector2 = Vector2(hull_position) + Vector2(hull.get_size()) * hull_anchor
	var turret_position := Vector2i(mount - Vector2(turret.get_size()) * turret_anchor)
	canvas.blend_rect(hull, Rect2i(Vector2i.ZERO, hull.get_size()), hull_position)
	_shade_contact(canvas, mount)
	canvas.blend_rect(turret, Rect2i(Vector2i.ZERO, turret.get_size()), turret_position)
	_cache[key] = ImageTexture.create_from_image(canvas)
	return _cache[key]

static func _resize_width(image: Image, width: int) -> void:
	var height: int = roundi(float(image.get_height()) * width / image.get_width())
	image.resize(width, height, Image.INTERPOLATE_LANCZOS)

static func _recess_turret_base(image: Image, weapon: StringName) -> void:
	# The card includes a display-like lower pedestal. Recess its lower edge into the hull.
	var end: float = image.get_height() * float(COMPOSITION.turret_base_cuts[weapon])
	var start: float = end - image.get_height() * COMPOSITION.turret_base_feather
	for y: int in range(floori(start), image.get_height()):
		var visibility: float = 1.0 - smoothstep(start, end, float(y))
		for x: int in range(image.get_width()):
			var color: Color = image.get_pixel(x, y)
			color.a *= visibility
			image.set_pixel(x, y, color)

static func _shade_contact(canvas: Image, mount: Vector2) -> void:
	# Darken existing hull pixels only: no floating ellipse outside its silhouette.
	var center: Vector2 = mount + COMPOSITION.contact_shadow_offset
	var radius: Vector2 = COMPOSITION.contact_shadow_radius
	var bounds := Rect2i(Vector2i(center - radius), Vector2i(radius * 2.0))
	bounds = bounds.intersection(Rect2i(Vector2i.ZERO, canvas.get_size()))
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			var distance: float = ((Vector2(x, y) - center) / radius).length()
			if distance >= 1.0: continue
			var color: Color = canvas.get_pixel(x, y)
			var shade: float = COMPOSITION.contact_shadow_opacity * (1.0 - smoothstep(0.2, 1.0, distance))
			color.r *= 1.0 - shade
			color.g *= 1.0 - shade
			color.b *= 1.0 - shade
			canvas.set_pixel(x, y, color)
