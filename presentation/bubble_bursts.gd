extends RefCounted
class_name BubbleBursts
## Transient droplets and muzzle bubbles advance exclusively on committed ticks.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

const ACCENTS = preload("res://presentation/toon_accent_group.gd")

var active: Array[Dictionary] = []

func spawn(parent: Node3D, position: Vector3, tick: int, style: AbilityEffectStyle, pop: bool, field: bool = false) -> void:
	if active.size() >= style.bubble_max_bursts: return
	var sprite: Sprite3D = TOON_FX.create(&"drop",&"water",0,style.bubble_landing_width_m if field else style.bubble_pop_width_m) if pop else TOON_FX.water(style.bubble_muzzle_width_m)

	sprite.position = position
	var camera := parent.get_viewport().get_camera_3d()
	if camera != null: sprite.position += camera.global_basis.z*style.art_camera_offset_m
	var group := Node3D.new()
	parent.add_child(group)
	group.add_child(sprite)
	var droplets: Node3D = null
	var wave: MeshInstance3D = null
	var duration: int = style.bubble_landing_ticks if field else style.bubble_pop_ticks if pop else style.bubble_muzzle_ticks
	if field:
		wave = MeshInstance3D.new()
		var quad := QuadMesh.new()
		var radius: float = preload("res://content/rules/bubble.tres").field_radius
		quad.size = Vector2.ONE*radius*2
		wave.mesh = quad
		wave.rotation.x = -PI/2
		wave.position = Vector3(position.x,style.ground_height+0.015,position.z)
		wave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = preload("res://presentation/shaders/toon_water_landing.gdshader")
		wave.material_override = material
		group.add_child(wave)
	if pop:
		droplets = ACCENTS.new()
		group.add_child(droplets)
		droplets.configure(&"water",sprite.position,Vector3.FORWARD,style.bubble_droplet_count,style.bubble_landing_drop_width_m if field else style.bubble_droplet_width_m,style.bubble_landing_drop_speed if field else style.bubble_droplet_speed,duration,style.bubble_droplet_gravity)
	active.append({"root":group,"droplets":droplets,"sprite":sprite,"start":tick,"duration":duration,"wave":wave,"pop":pop})
	step(tick)

func step(tick: int) -> void:
	var alive: Array[Dictionary] = []
	for entry: Dictionary in active:
		var sprite: Sprite3D = entry.sprite
		var fraction: float = float(tick-entry.start)/entry.duration
		if fraction >= 1.0:
			(entry.root as Node).queue_free()
			continue
		var eased: float = 1.0-pow(1.0-fraction,2)
		sprite.scale = Vector3.ONE*lerpf(0.40,1.20,eased)
		TOON_FX.advance(sprite,fraction)
		if entry.droplets != null: entry.droplets.step(tick-entry.start)
		if entry.wave != null: (entry.wave.material_override as ShaderMaterial).set_shader_parameter("life",fraction)
		alive.append(entry)
	active = alive

func clear() -> void:
	for entry: Dictionary in active: (entry.root as Node).queue_free()
	active.clear()
