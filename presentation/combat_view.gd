extends Node3D
class_name CombatView
## Disposable visual nodes track authoritative projectile data.

@export var style: CombatEffectStyle = preload("res://content/presentation/default_vfx.tres")
var ability_style: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var projectiles: ProjectileSystem
var _visuals: Dictionary = {}
var _paused: bool = false
var ability_art_enabled: bool = false
var _effects: Array[Tween] = []

func _process(_delta: float) -> void:
	if projectiles == null or _paused:
		return
	var alive: Dictionary = {}
	for shot: ProjectileState in projectiles.active:
		alive[shot.projectile_id] = true
		if not _visuals.has(shot.projectile_id):
			var color := Color("ffdc73") if shot.team_id == 0 else Color("ff6b64")
			var visual: Node3D = _sphere(0.13,color)
			if shot.ability_damage and not shot.pierce_damage.is_empty():
				visual.free()
				visual = _breach_projectile(color)
				visual.rotation.y = -atan2(shot.direction.x,-shot.direction.z)
			elif shot.storm_round:
				visual.free()
				visual = _storm_projectile(color)
				visual.rotation.y = -atan2(shot.direction.x,-shot.direction.z)
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
			if ability_art_enabled: return
			_flash(style.muzzle, event.position, style.muzzle_width_m, style.muzzle_duration_s)
		&"projectile_hit":
			if ability_art_enabled: return
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

func _breach_projectile(color: Color) -> Node3D:
	var root := Node3D.new()
	var core := _sphere(ability_style.breach_core_width_m,color.lightened(0.65))
	core.scale = Vector3(1,1,3)
	root.add_child(core)
	var tail := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = ability_style.breach_core_width_m*0.7
	mesh.bottom_radius = 0.01
	mesh.height = ability_style.breach_trail_m
	mesh.radial_segments = 8
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh.material = material
	tail.mesh = mesh
	tail.rotation.x = -PI/2
	tail.position.z = ability_style.breach_trail_m*0.5
	tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tail)
	return root

func _storm_projectile(team_color: Color) -> Node3D:
	var root := Node3D.new()
	var core := _sphere(ability_style.storm_core_width_m,Color("fff1cb"))
	core.scale.z = 3.0
	root.add_child(core)
	var tail := _sphere(ability_style.storm_core_width_m,ability_style.storm_color)
	tail.scale = Vector3(0.7,0.7,ability_style.storm_trail_m/ability_style.storm_core_width_m)
	tail.position.z = ability_style.storm_trail_m*0.5
	root.add_child(tail)
	var marker := _sphere(ability_style.storm_core_width_m*0.65,team_color)
	marker.position.z = ability_style.storm_trail_m
	root.add_child(marker)
	return root
