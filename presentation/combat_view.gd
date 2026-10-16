extends Node3D
class_name CombatView
## Disposable visual nodes track authoritative projectile data.

@export var style: CombatEffectStyle = preload("res://content/presentation/default_vfx.tres")
var weapon_style: WeaponVisualStyle = preload("res://content/presentation/weapon_visuals.tres")
var ability_style: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var projectiles: ProjectileSystem
var _visuals: Dictionary = {}
var _launches: Dictionary = {}
var _paused: bool = false
var ability_art_enabled: bool = false
var _effects: Array[Tween] = []
var _tick: int = 0
var _bubble_bursts := BubbleBursts.new()

func _process(_delta: float) -> void:
	if projectiles == null or _paused:
		return
	var alive: Dictionary = {}
	for shot: ProjectileState in projectiles.active:
		alive[shot.projectile_id] = true
		if _visuals.has(shot.projectile_id) and _visuals[shot.projectile_id].get_meta("kind", &"") != shot.kind:
			_visuals[shot.projectile_id].queue_free()
			_visuals.erase(shot.projectile_id)
		if not _visuals.has(shot.projectile_id):
			var color := Color("ffdc73") if shot.team_id == 0 else Color("ff6b64")
			var visual: Node3D = WeaponProjectileVisual.create(shot.weapon_id,shot.team_id,weapon_style)
			visual.rotation.y = -atan2(shot.direction.x,-shot.direction.z)
			if shot.kind in [&"bubble_round",&"bubble_barrier",&"bubble_lob",&"bubble_field"]:
				visual.free()
				var bubble := BubbleVisual.new()
				bubble.configure(shot.radius,shot.team_id,shot.kind in [&"bubble_barrier",&"bubble_field"],ability_style)
				visual = bubble
			elif shot.ability_damage and not shot.pierce_damage.is_empty():
				visual.free()
				visual = _breach_projectile(color)
				visual.rotation.y = -atan2(shot.direction.x,-shot.direction.z)
			elif shot.storm_round:
				visual.free()
				visual = _storm_projectile(color)
				visual.rotation.y = -atan2(shot.direction.x,-shot.direction.z)
			visual.set_meta("kind",shot.kind)
			add_child(visual)
			_visuals[shot.projectile_id] = visual
		_visuals[shot.projectile_id].position = shot.position
		if _launches.has(shot.projectile_id):
			var launch: Dictionary = _launches[shot.projectile_id]
			var blend: float = clampf(1.0-float(_tick-launch.tick)/weapon_style.launch_blend_ticks,0,1)
			_visuals[shot.projectile_id].position += launch.offset*blend
		if _visuals[shot.projectile_id] is BubbleVisual:
			(_visuals[shot.projectile_id] as BubbleVisual).present(shot,_tick)
			# BubbleVisual owns its membrane animation; offset the disposable root afterward.
			if _launches.has(shot.projectile_id):
				var launch: Dictionary = _launches[shot.projectile_id]
				_visuals[shot.projectile_id].position += launch.offset*clampf(1.0-float(_tick-launch.tick)/weapon_style.launch_blend_ticks,0,1)
	for id: int in _visuals.keys():
		if not alive.has(id):
			_visuals[id].queue_free()
			_visuals.erase(id)
	for id: int in _launches.keys():
		if not alive.has(id): _launches.erase(id)

func on_event(event: Dictionary) -> void:
	# Only committed facts create effects; requesting fire never shows a muzzle flash.
	if _paused:
		return
	_tick = int(event.get("tick",_tick))
	if event.has("visual_muzzle_position") and event.has("authoritative_muzzle_position"):
		var ids: Array = event.get("projectile_ids",[event.projectile_id] if event.has("projectile_id") else [])
		for id: int in ids:
			_launches[id] = {"tick":_tick,"offset":event.visual_muzzle_position-event.authoritative_muzzle_position}
	_bubble_bursts.step(_tick)
	match event.kind:
		&"weapon_fired":
			if event.get("weapon",&"") == &"bubble_cannon":
				_bubble_bursts.spawn(self,event.position,_tick,ability_style,false)
				return
			if ability_art_enabled: return
			_flash(style.muzzle, event.position, style.muzzle_width_m, style.muzzle_duration_s)
		&"projectile_hit":
			if event.get("bubble",false):
				_bubble_bursts.spawn(self,event.position,_tick,ability_style,true)
				return
			if ability_art_enabled: return
			_flash(style.impact, event.position, style.impact_width_m, style.impact_duration_s)
		&"entity_died":
			_flash(style.explosion, event.position, style.explosion_width_m, style.explosion_duration_s)
		&"match_finished":
			_bubble_bursts.clear()
			_launches.clear()

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
	for i: int in range(2):
		var hoop := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = ability_style.breach_core_width_m*(1.4+i*0.3)
		ring.outer_radius = ring.inner_radius+weapon_style.signature_width*0.5
		ring.rings = 16
		ring.ring_segments = 4
		hoop.mesh = ring
		hoop.material_override = WeaponProjectileVisual.material(color.lightened(0.5))
		hoop.rotation.x = PI/2
		hoop.position.z = i*ability_style.breach_trail_m*0.35
		hoop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(hoop)
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
	for side: int in [-1,1]:
		var rail := Node3D.new()
		rail.position.x = side*ability_style.storm_core_width_m*1.5
		WeaponProjectileVisual.rod(rail,ability_style.storm_core_width_m*0.3,weapon_style.storm_trace_length*1.6,weapon_style.storm_trace_length*0.6,ability_style.storm_color)
		root.add_child(rail)
	return root
