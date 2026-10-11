extends Node3D
class_name CombatView
## Disposable visual nodes track authoritative projectile data.

@export var style: CombatEffectStyle = preload("res://content/presentation/default_vfx.tres")
var projectiles: ProjectileSystem
var _visuals: Dictionary = {}
var _paused: bool = false
var _effects: Array[Tween] = []

func _process(_delta: float) -> void:
	if projectiles == null or _paused:
		return
	var alive: Dictionary = {}
	for shot: ProjectileState in projectiles.active:
		alive[shot.projectile_id] = true
		if not _visuals.has(shot.projectile_id):
			var color := Color("ffdc73") if shot.team_id == 0 else Color("ff6b64")
			var visual := _sphere(0.13, color)
			add_child(visual)
			_visuals[shot.projectile_id] = visual
		_visuals[shot.projectile_id].position = shot.position
	for id: int in _visuals.keys():
		if not alive.has(id):
			_visuals[id].queue_free()
			_visuals.erase(id)

func on_event(event: Dictionary) -> void:
	# Only committed facts create effects; requesting fire never shows a muzzle flash.
	if _paused:
		return
	match event.kind:
		&"weapon_fired":
			_flash(style.muzzle, event.position, style.muzzle_width_m, style.muzzle_duration_s)
		&"projectile_hit":
			_flash(style.impact, event.position, style.impact_width_m, style.impact_duration_s)
		&"entity_died":
			_flash(style.explosion, event.position, style.explosion_width_m, style.explosion_duration_s)

func _flash(texture: Texture2D, center: Vector3, width: float, duration: float) -> void:
	_effects = _effects.filter(func(effect: Tween) -> bool: return effect.is_valid())
	# Cosmetic overload may drop an effect, never an authoritative projectile.
	if _effects.size() >= style.max_active:
		return
	var flash := Sprite3D.new()
	flash.texture = texture
	flash.pixel_size = width / float(texture.get_width())
	flash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	flash.shaded = false
	flash.no_depth_test = false
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.position = center
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		# A cosmetic camera-facing offset keeps contact art outside the hit surface.
		flash.position += camera.global_basis.z * style.camera_offset_m
	flash.scale = Vector3.ONE * 0.65
	add_child(flash)
	var tween := create_tween()
	_effects.append(tween)
	tween.finished.connect(func() -> void: _effects.erase(tween))
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * 1.12, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, duration * 0.8).set_delay(duration * 0.2)
	tween.chain().tween_callback(flash.queue_free)

func _sphere(radius: float, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	sphere.material = material
	visual.mesh = sphere
	return visual

func set_paused(value: bool) -> void:
	_paused = value
	for tween: Tween in _effects:
		if tween.is_valid():
			if value:
				tween.pause()
			else:
				tween.play()
