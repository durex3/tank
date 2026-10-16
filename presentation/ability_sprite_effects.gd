extends Node3D
class_name AbilitySpriteEffects
## Alpha art aged only by committed ticks. Persistent clouds/charge are entity-scoped.

const SHOCK_SHADER := preload("res://presentation/shaders/shock_sector.gdshader")
var style: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var weapon_style: WeaponVisualStyle = preload("res://content/presentation/weapon_visuals.tres")
var rules: BasicAbilityRules = preload("res://content/rules/basic_abilities.tres")
var _effects: Array[Dictionary] = []
var _smoke: Dictionary = {}
var _charge: Dictionary = {}
var _phases: Dictionary = {}
var _heat: Dictionary = {}
var _messages: Array[Dictionary] = []

func on_event(event: Dictionary) -> void:
	_age(event.tick)
	match event.kind:
		&"ability_started": _phases[event.source_id] = event.phase
		&"ability_state":
			_phases[event.source_id] = event.phase if event.alive else &"idle"
			_update_charge(event)
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
				_guard_message(event,"拦截泡 %d/2 · 减速15%%" % event.bubble_hits)
			elif event.get("slow_ticks",0) > 0:
				_guard_message(event,"减速15%")
			if event.get("guarded",false):
				var spark := _flash(style.impact,event.position,style.guard_spark_width_m,event.tick,style.guard_hit_ticks)
				if spark != null: spark.modulate = style.guard_color
				_guard_message(event)
		&"ability_fired":
			if event.ability == &"breach": pass
			elif event.ability == &"shock": _shock(event)
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
	_effects.append({"sprite":sprite,"start":tick,"until":tick+duration,"shape":shape})
	return sprite

func _sprite(texture: Texture2D, width: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = width/texture.get_width()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sprite

func _shock(event: Dictionary) -> void:
	if _effects.size() >= style.max_sprites: return
	var node := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE*rules.shock_range*2.0
	var material := ShaderMaterial.new()
	material.shader = SHOCK_SHADER
	material.set_shader_parameter("dust",style.shockwave)
	material.set_shader_parameter("half_angle_cos",cos(deg_to_rad(rules.shock_half_angle)))
	node.mesh = plane
	node.material_override = material
	node.position = event.position+Vector3.UP*0.10
	node.rotation.y = -event.yaw
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.scale = Vector3.ONE*0.35
	add_child(node)
	_effects.append({"sprite":node,"material":material,"start":event.tick,"until":event.tick+style.shock_visual_ticks})

func _age(tick: int) -> void:
	var alive: Array[Dictionary] = []
	for effect: Dictionary in _effects:
		var node: Node3D = effect.sprite
		if tick >= effect.until: node.queue_free()
		else:
			var fraction: float = float(tick-effect.start)/(effect.until-effect.start)
			var eased: float = 1.0-pow(1.0-fraction,2)
			if node is Sprite3D:
				(node as Sprite3D).modulate.a = 1.0-fraction
				node.scale = effect.get("shape",Vector3.ONE)*(0.7+eased*0.5)
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

func _update_charge(event: Dictionary) -> void:
	var id: int = event.source_id
	if not event.alive or event.phase != &"breach":
		if _charge.has(id):
			_charge[id].queue_free()
			_charge.erase(id)
		return
	if not _charge.has(id):
		var sprite := _sprite(style.muzzle,style.charge_core_m*2)
		add_child(sprite)
		_charge[id] = sprite
	var core: Sprite3D = _charge[id]
	var progress: float = clampf(1.0-float(event.remaining)/rules.breach_charge,0,1)
	core.position = event.get("visual_muzzle_position", event.position+Vector3(sin(event.yaw),0,-cos(event.yaw))*ProjectileSystem.MUZZLE_OFFSET+Vector3.UP*ProjectileSystem.SHOT_HEIGHT)
	var camera := get_viewport().get_camera_3d()
	if camera != null: core.position += camera.global_basis.z*style.art_camera_offset_m
	core.scale = Vector3.ONE*(0.3+progress*0.7)
	core.modulate = Color(style.breach_color,0.4+progress*0.6)

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
			sprite.modulate = Color(0.85,0.89,0.92,style.smoke_opacity*fade)
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
	for core: Sprite3D in _charge.values(): core.queue_free()
	for entry: Dictionary in _messages: (entry.label as Label3D).queue_free()
	_effects.clear()
	_smoke.clear()
	_charge.clear()
	for plumes: Array in _heat.values():
		for plume: Sprite3D in plumes: plume.queue_free()
	_heat.clear()
	_phases.clear()
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
		plume.modulate = Color(0.65,0.69,0.72,style.heat_smoke_opacity*(1.0-phase))
		plume.scale = Vector3.ONE*(0.6+phase*0.6)
