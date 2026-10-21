extends Node3D
class_name CombatView
## Disposable visual nodes track authoritative projectile data.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

@export var style: CombatEffectStyle = preload("res://content/presentation/default_vfx.tres")
var weapon_style: WeaponVisualStyle = preload("res://content/presentation/weapon_visuals.tres")
var ability_style: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var projectiles: ProjectileSystem
var _visuals: Dictionary = {}
var _launches: Dictionary = {}
var _paused: bool = false
var ability_art_enabled: bool = false
var _effects: Array[Dictionary] = []
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
				bubble.configure(shot.radius,shot.team_id,shot.kind in [&"bubble_barrier",&"bubble_field"],ability_style,shot.kind == &"bubble_lob")
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
	_age_flashes(_tick)
	match event.kind:
		&"weapon_fired":
			if event.get("weapon",&"") == &"bubble_cannon":
				_bubble_bursts.spawn(self,event.position,_tick,ability_style,false)
				return
			if ability_art_enabled: return
			_flash(style.muzzle, event.position, style.muzzle_width_m, style.muzzle_duration_s)
		&"projectile_hit":
			if event.get("bubble",false):
				_bubble_bursts.spawn(self,event.position,_tick,ability_style,true,event.get("field",false))
				return
			if ability_art_enabled: return
			_flash(style.impact, event.position, style.impact_width_m, style.impact_duration_s)
		&"entity_died":
			_flash(style.explosion, event.position, style.explosion_width_m, style.explosion_duration_s)
		&"match_finished":
			_bubble_bursts.clear()
			for entry: Dictionary in _effects: (entry.node as Node).queue_free()
			_effects.clear()
			_launches.clear()

func _flash(texture: Texture2D, center: Vector3, width: float, duration: float) -> void:
	if _effects.size() >= style.max_active: return
	var cell: int = 3 if texture == style.explosion else (0 if texture == style.muzzle else 1)
	var flash: Sprite3D = TOON_FX.create(&"flash",&"warm",cell,width)
	flash.position = center
	var camera := get_viewport().get_camera_3d()
	if camera != null: flash.position += camera.global_basis.z*style.camera_offset_m
	add_child(flash)
	_effects.append({"node":flash,"start":_tick,"duration":maxi(1,ceili(duration*60))})

func _age_flashes(tick: int) -> void:
	var keep: Array[Dictionary] = []
	for entry: Dictionary in _effects:
		var life: float = float(tick-int(entry.start))/int(entry.duration)
		if life >= 1.0: (entry.node as Node).queue_free()
		else:
			var sprite: Sprite3D = entry.node
			TOON_FX.advance(sprite,life)
			sprite.scale = Vector3.ONE*lerpf(0.65,1.12,life)
			keep.append(entry)
	_effects = keep

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

func _breach_projectile(_color: Color) -> Node3D:
	var root := Node3D.new()
	var tracer: Sprite3D = TOON_FX.create(&"bolt",&"warm",2,ability_style.breach_trail_m)
	tracer.modulate = ability_style.breach_color
	root.add_child(tracer)
	return root

func _storm_projectile(_team_color: Color) -> Node3D:
	var root := Node3D.new()
	var head := MeshInstance3D.new()
	head.name = "StormBulletHead"
	var capsule := CapsuleMesh.new()
	capsule.radius = ability_style.storm_head_radius_m
	capsule.height = ability_style.storm_head_length_m
	capsule.radial_segments = 8
	capsule.rings = 2
	head.mesh = capsule
	head.rotation.x = PI/2
	head.material_override = WeaponProjectileVisual.material(Color("ffe49b"))
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(head)
	var tracer := MeshInstance3D.new()
	tracer.name = "StormBulletTail"
	var quad := QuadMesh.new()
	quad.size = Vector2(ability_style.storm_core_width_m*2,ability_style.storm_trail_m)
	tracer.mesh = quad
	tracer.rotation.x = -PI/2
	tracer.position.z = ability_style.storm_head_length_m*0.15+ability_style.storm_trail_m*0.5
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = preload("res://presentation/shaders/toon_ballistic_tail.gdshader")
	tracer.material_override = material
	root.add_child(tracer)
	return root
