extends Node3D
class_name AbilitySpriteEffects
## Toon sprites age only on committed ticks; persistent smoke is entity-scoped.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

var style: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var weapon_style: WeaponVisualStyle = preload("res://content/presentation/weapon_visuals.tres")
var rules: BasicAbilityRules = preload("res://content/rules/basic_abilities.tres")
var _effects: Array[Dictionary] = []
var _smoke: Dictionary = {}
var _phases: Dictionary = {}
var _heat: Dictionary = {}
var _owner: int = -1
var _seen: Dictionary = {}
var _messages: Array[Dictionary] = []

func on_event(event: Dictionary) -> void:
	_owner = int(event.get("source_id",event.get("target_id",-1)))
	_age(event.tick)
	for key: String in _seen.keys():
		if event.tick > int(_seen[key]): _seen.erase(key)
	if event.kind in [&"weapon_fired",&"projectile_hit"]:
		var key: String = "%s:%s:%s:%s" % [event.kind,event.tick,event.get("source_id",-1),event.get("projectile_id",event.get("projectile_ids",[]))]
		if _seen.has(key): return
		_seen[key] = event.tick+style.impact_ticks
	if event.kind in [&"entity_died",&"entity_respawned"]:
		_remove_owner(int(event.get("entity_id",event.get("target_id",event.get("source_id",-1)))))
	match event.kind:
		&"ability_started": _phases[event.source_id] = event.phase
		&"ability_state":
			_phases[event.source_id] = event.phase if event.alive else &"idle"
			if not event.alive: _remove_owner(int(event.source_id))
			_update_heat(event)
		&"weapon_fired":
			if event.get("weapon",&"") == &"bubble_cannon": return
			var storm: bool = _phases.get(event.source_id,&"idle") == &"storm"
			var weapon: StringName = event.get("weapon",&"")
			var width: float = style.muzzle_width_m
			var shape := Vector3.ONE
			match weapon:
				&"cannon": width = weapon_style.cannon_muzzle_width
				&"autocannon":
					width = weapon_style.needle_muzzle_width
					shape = weapon_style.needle_flash_shape
				&"scatter":
					width = weapon_style.scatter_muzzle_width
					shape = weapon_style.scatter_flash_shape
			_flash(style.muzzle,event.position,style.storm_muzzle_width_m if storm else width,event.tick,style.storm_muzzle_ticks if storm else style.muzzle_ticks,shape)
			if weapon == &"cannon": _muzzle_smoke(event)

		&"projectile_hit":
			if not event.get("bubble",false) and not event.get("ability_damage",false):
				var weapon: StringName = event.get("weapon",&"")
				if weapon == &"cannon": return
				var texture: Texture2D = weapon_style.cannon_impact if weapon == &"cannon" else style.impact
				var width: float = weapon_style.impact_width if weapon == &"cannon" else style.impact_width_m
				var shape := Vector3.ONE
				if weapon == &"autocannon":
					width = weapon_style.needle_impact_width
					shape = weapon_style.needle_flash_shape
				elif weapon == &"scatter":
					width = weapon_style.scatter_impact_width
					shape = weapon_style.scatter_flash_shape
				_flash(texture,event.position,width,event.tick,weapon_style.impact_ticks,shape)
		&"damage_applied":
			if event.get("bubble_hits",0) > 0:
				_guard_message(event,"泡泡命中 · 减速")
			elif event.get("slow_ticks",0) > 0:
				_guard_message(event,"减速")
			if event.get("guarded",false):
				_guard_message(event)
		&"ability_fired":
			if event.ability == &"breach": pass
			elif event.ability == &"shock": pass
		&"ability_zones": _update_smoke(event.zones,event.tick)
		&"match_finished": clear()

func _flash(texture: Texture2D, position_value: Vector3, width: float, tick: int, duration: int, shape: Vector3 = Vector3.ONE) -> Sprite3D:
	if _effects.size() >= style.max_sprites: return null
	var sprite: Sprite3D = _sprite(texture,width)
	sprite.position = position_value
	var camera := get_viewport().get_camera_3d()
	if camera != null: sprite.position += camera.global_basis.z*style.art_camera_offset_m
	add_child(sprite)
	sprite.scale = shape
	_effects.append({"sprite":sprite,"start":tick,"until":tick+duration,"shape":shape,"owner":_owner})
	return sprite

func _sprite(texture: Texture2D, width: float) -> Sprite3D:
	if texture == style.smoke:
		return TOON_FX.create(&"smoke", &"dust", 1, width)
	return TOON_FX.contact(width,&"warm",0 if texture == style.muzzle else 1)

func _age(tick: int) -> void:
	var alive: Array[Dictionary] = []
	for effect: Dictionary in _effects:
		var node: Node3D = effect.sprite
		if tick >= effect.until: node.queue_free()
		else:
			var fraction: float = clampf(float(tick-effect.start)/(effect.until-effect.start),0,1)
			if effect.has("drift"):
				var smoke: Sprite3D = node
				smoke.visible = tick >= effect.start
				smoke.position = effect.origin+effect.drift*fraction
				smoke.scale = Vector3.ONE*lerpf(0.4,1.15,fraction)
				smoke.modulate.a = style.muzzle_smoke_alpha*sin(fraction*PI)
				TOON_FX.advance(smoke,fraction)
				alive.append(effect)
				continue
			var eased: float = 1.0-pow(1.0-fraction,2)
			if node is Sprite3D:
				TOON_FX.advance(node as Sprite3D, fraction)
				node.scale = effect.get("shape",Vector3.ONE)*(0.65+sin(fraction*PI)*0.4)
			else:
				(effect.material as ShaderMaterial).set_shader_parameter("opacity",1.0-fraction)
				node.scale = Vector3.ONE*(0.35+eased*0.65)
			alive.append(effect)
	_effects = alive
	var messages: Array[Dictionary] = []
	for entry: Dictionary in _messages:
		var label: Label3D = entry.label
		if tick >= entry.until: label.queue_free()
		else:
			var fraction: float = float(tick-entry.start)/style.guard_label_ticks
			label.modulate.a = 1.0-fraction
			label.position = entry.position+Vector3.UP*fraction*0.3
			messages.append(entry)
	_messages = messages

func _update_smoke(zones: Array, tick: int) -> void:
	var alive: Dictionary = {}
	var used: int = 0
	for zone: Dictionary in zones:
		var layers: int = mini(style.smoke_layers,style.max_smoke_sprites-used)
		if layers <= 0: break
		used += layers
		alive[zone.owner_id] = true
		if not _smoke.has(zone.owner_id): _smoke[zone.owner_id] = []
		var cloud: Array = _smoke[zone.owner_id]
		while cloud.size() > layers: (cloud.pop_back() as Sprite3D).queue_free()
		while cloud.size() < layers:
			var sprite := _sprite(style.smoke,rules.smoke_radius*style.smoke_art_scale)
			add_child(sprite)
			cloud.append(sprite)
		var fraction: float = clampf(1.0-float(zone.until_tick-tick)/rules.smoke_ticks,0,1)
		var fade: float = minf(1.0,float(zone.until_tick-tick)/style.smoke_fade_ticks)
		for i: int in range(cloud.size()):
			var sprite: Sprite3D = cloud[i]
			var angle: float = float(i)*TAU/cloud.size()+fraction*0.3
			var offset := Vector3(cos(angle)*style.smoke_layer_spread_m,float(i)*0.13,sin(angle)*style.smoke_layer_spread_m)
			sprite.position = zone.position+offset+Vector3.UP*(style.smoke_height_m+fraction*style.smoke_rise_m)
			sprite.modulate = Color(1,1,1,style.smoke_opacity*fade)
			TOON_FX.advance(sprite, fraction)
			sprite.scale = Vector3.ONE*(0.8+minf(1.0,fraction*8)*0.2)
	for id: int in _smoke.keys():
		if not alive.has(id):
			for sprite: Sprite3D in _smoke[id]: sprite.queue_free()
			_smoke.erase(id)

func _guard_message(event: Dictionary, text: String = "正面格挡") -> void:
	for entry: Dictionary in _messages:
		if event.has("target_id") and entry.start == event.tick and entry.get("target_id",-1) == event.target_id:
			(entry.label as Label3D).text = text
			return
	if _messages.size() >= style.max_labels: return
	var label := Label3D.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","PingFang SC","Hiragino Sans GB","Noto Sans CJK SC"])
	font.font_weight = 700
	label.font = font
	label.text = text
	label.font_size = 28
	label.pixel_size = 0.012
	label.modulate = Color("c2ecff")
	label.outline_size = 6
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = event.position+Vector3.UP*1.0
	add_child(label)
	_messages.append({"label":label,"start":event.tick,"until":event.tick+style.guard_label_ticks,"position":label.position,"target_id":event.get("target_id",-1)})

func clear() -> void:
	for effect: Dictionary in _effects: (effect.sprite as Node3D).queue_free()
	for cloud: Array in _smoke.values():
		for sprite: Sprite3D in cloud: sprite.queue_free()
	for entry: Dictionary in _messages: (entry.label as Label3D).queue_free()
	_effects.clear()
	_smoke.clear()
	for plumes: Array in _heat.values():
		for plume: Sprite3D in plumes: plume.queue_free()
	_heat.clear()
	_phases.clear()
	_seen.clear()
	_messages.clear()

func _update_heat(event: Dictionary) -> void:
	var id: int = event.source_id
	if not event.alive or event.phase != &"cooling":
		if _heat.has(id):
			for plume: Sprite3D in _heat[id]: plume.queue_free()
			_heat.erase(id)
		return
	if not _heat.has(id):
		var plumes: Array[Sprite3D] = []
		for i: int in range(2):
			var plume := _sprite(style.smoke,style.heat_smoke_width_m)
			add_child(plume)
			plumes.append(plume)
		_heat[id] = plumes
	var aim := Vector3(sin(event.yaw),0,-cos(event.yaw))
	var right := Vector3(-aim.z,0,aim.x)
	for i: int in range(2):
		var phase: float = float((event.tick+i*12)%24)/24.0
		var plume: Sprite3D = _heat[id][i]
		plume.position = event.position+right*(i*2-1)*style.storm_rail_offset_m+Vector3.UP*(style.vent_height_m+phase*style.heat_smoke_rise_m)
		var camera := get_viewport().get_camera_3d()
		if camera != null: plume.position += camera.global_basis.z*style.art_camera_offset_m
		plume.modulate = Color(1,1,1,style.heat_smoke_opacity)
		TOON_FX.advance(plume, phase)
		plume.scale = Vector3.ONE*(0.6+phase*0.6)

func _remove_owner(id: int) -> void:
	var keep: Array[Dictionary] = []
	for effect: Dictionary in _effects:
		if effect.get("owner",-1) == id: (effect.sprite as Node).queue_free()
		else: keep.append(effect)
	_effects = keep
	for cache: Dictionary in [_heat, _smoke]:
		if not cache.has(id): continue
		var value: Variant = cache[id]
		if value is Array:
			for node: Node in value: node.queue_free()
		else: (value as Node).queue_free()
		cache.erase(id)

func _muzzle_smoke(event: Dictionary) -> void:
	if _effects.size() >= style.max_sprites: return
	var smoke: Sprite3D = TOON_FX.create(&"smoke",&"dust",2,style.muzzle_smoke_width_m)
	smoke.position = event.position
	smoke.visible = false
	add_child(smoke)
	var direction: Vector3 = event.get("direction",Vector3.FORWARD)
	_effects.append({"sprite":smoke,"owner":_owner,"start":event.tick+style.muzzle_smoke_delay_ticks,"until":event.tick+style.muzzle_smoke_delay_ticks+style.muzzle_smoke_ticks,"origin":event.position,"drift":direction*style.muzzle_smoke_drift_m+Vector3.UP*style.muzzle_smoke_drift_m})
