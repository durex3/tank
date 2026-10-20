extends Node3D
class_name AbilitySignatureEffects
## Ultimates share toon data textures. All motion and erosion derive from event ticks.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

var style: WeaponVisualStyle = preload("res://content/presentation/weapon_visuals.tres")
var colors: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var rules: BasicAbilityRules = preload("res://content/rules/basic_abilities.tres")
var actors: Dictionary = {}
var bursts: Array[Dictionary] = []
var _seen: Dictionary = {}
var _tick: int = -1

func on_event(event: Dictionary) -> void:
	var tick: int = event.tick
	if tick < _tick: return
	_tick = tick
	_age(tick)
	match event.kind:
		&"match_finished": clear()
		&"entity_died", &"entity_respawned": _remove_actor(int(event.get("target_id",-1)))
		&"ability_state":
			if event.alive: _draw_state(event)
			else: _remove_actor(int(event.source_id))
		&"ability_fired": _release(event)

func _draw_state(state: Dictionary) -> void:
	var id: int = state.source_id
	var phase: StringName = state.phase
	if phase not in [&"breach",&"storm",&"bubble"]:
		_remove_state(id)
		return
	if actors.has(id) and actors[id].phase != phase: _remove_state(id)
	if not actors.has(id):
		var created: Sprite3D = TOON_FX.contact(colors.charge_core_m*1.4,&"warm",2) if phase == &"breach" else TOON_FX.contact(colors.storm_indicator_width_m,&"warm",2) if phase == &"storm" else TOON_FX.water(colors.bubble_muzzle_width_m)
		add_child(created)
		actors[id] = {"node":created,"phase":phase,"start":state.tick}
	var entry: Dictionary = actors[id]
	var sprite: Sprite3D = entry.node
	var aim := Vector3(sin(state.yaw),0,-cos(state.yaw))
	sprite.position = state.get("visual_muzzle_position",state.position+aim*ProjectileSystem.MUZZLE_OFFSET+Vector3.UP*ProjectileSystem.SHOT_HEIGHT)
	if phase == &"breach":
		var progress: float = clampf(1.0-float(state.remaining)/rules.breach_charge,0,1)
		sprite.scale = Vector3.ONE*lerpf(0.55,1.0,progress)
	elif phase == &"storm":
		sprite.position = state.position-aim*colors.storm_rail_offset_m+Vector3.UP*colors.vent_height_m
		sprite.modulate.a = 1.0
		sprite.scale = Vector3.ONE*(0.8+0.15*sin(float(state.tick-int(entry.start))*0.35))
	else:
		sprite.scale = Vector3.ONE*(0.8+0.2*sin(float(state.tick)*colors.bubble_bob_rate))

func _release(event: Dictionary) -> void:
	var key: String = "%s:%s:%s" % [event.source_id,event.ability,event.tick]
	if _seen.has(key) or bursts.size() >= style.max_signatures: return
	_seen[key] = event.tick+style.signature_ticks
	var root := Node3D.new()
	add_child(root)
	var duration: int = style.energy_release_ticks if event.ability == &"breach" else style.signature_ticks
	var burst: Dictionary = {"node":root,"event":event.duplicate(),"start":event.tick,"until":event.tick+duration,"sprites":[]}
	if event.ability == &"breach":
		var end: Vector3 = event.get("end",event.position)
		var direction: Vector3 = end-event.position
		if direction.length_squared() > 0.0001:
			var beam := MeshInstance3D.new()
			var quad := QuadMesh.new()
			quad.size = Vector2(style.energy_beam_width,direction.length())
			beam.mesh = quad
			var forward: Vector3 = direction.normalized()
			var lateral: Vector3 = forward.cross(Vector3.UP).normalized()
			beam.basis = Basis(lateral,forward,lateral.cross(forward))
			beam.position = (event.position+end)*0.5
			beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var material := ShaderMaterial.new()
			material.shader = preload("res://presentation/shaders/armor_piercing_trace.gdshader")
			material.set_shader_parameter("length_m",direction.length())
			material.set_shader_parameter("wake_half_width",style.breach_trace_width_m/style.energy_beam_width*0.5)
			material.set_shader_parameter("wake_strength",style.breach_trace_strength)
			material.set_shader_parameter("life",0.0)
			material.set_shader_parameter("phase",0.0)
			beam.material_override = material
			root.add_child(beam)
			burst.material = material
			var muzzle: Sprite3D = TOON_FX.contact(style.breach_release_radius*1.1,&"warm",0)
			muzzle.position = event.position
			muzzle.modulate = Color.WHITE
			root.add_child(muzzle)
			burst.sprites.append(muzzle)

	else:
		var sprite: Sprite3D = TOON_FX.create(&"drop" if event.ability == &"bubble" else &"smoke",&"water" if event.ability == &"bubble" else &"dust",0,colors.bubble_pop_width_m if event.ability == &"bubble" else colors.impact_width_m)
		sprite.position = event.position
		root.add_child(sprite)
		burst.sprites.append(sprite)
	bursts.append(burst)

func _age(tick: int) -> void:
	for key: String in _seen.keys():
		if tick >= int(_seen[key]): _seen.erase(key)
	var keep: Array[Dictionary] = []
	for burst: Dictionary in bursts:
		if tick >= burst.until:
			(burst.node as Node).queue_free()
			continue
		var life: float = clampf(float(tick-int(burst.start))/maxi(1,int(burst.until)-int(burst.start)),0,1)
		for sprite: Sprite3D in burst.sprites:
			TOON_FX.advance(sprite,life)
			sprite.scale = Vector3.ONE*(0.65+sin(life*PI)*0.45)
			if burst.event.ability == &"breach":
				sprite.modulate.a = 1.0-smoothstep(0.18,0.5,life)
		if burst.has("material"):
			var material: ShaderMaterial = burst.material
			material.set_shader_parameter("life",life)
			material.set_shader_parameter("phase",float(tick-int(burst.start))/3.0)
		keep.append(burst)
	bursts = keep

func _remove_state(id: int) -> void:
	if actors.has(id):
		(actors[id].node as Node).queue_free()
		actors.erase(id)

func _remove_actor(id: int) -> void:
	_remove_state(id)
	var keep: Array[Dictionary] = []
	for burst: Dictionary in bursts:
		if burst.event.source_id == id: (burst.node as Node).queue_free()
		else: keep.append(burst)
	bursts = keep

func clear() -> void:
	for id: int in actors.keys(): _remove_state(id)
	for burst: Dictionary in bursts: (burst.node as Node).queue_free()
	bursts.clear()
	_seen.clear()
	_tick = -1
