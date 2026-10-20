extends RefCounted
class_name BubbleBursts
## Transient droplets and muzzle bubbles advance exclusively on committed ticks.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

var active: Array[Dictionary] = []

func spawn(parent: Node3D, position: Vector3, tick: int, style: AbilityEffectStyle, pop: bool) -> void:
	if active.size() >= style.bubble_max_bursts: return
	var sprite: Sprite3D = TOON_FX.create(&"drop",&"water",0 if pop else 2,style.bubble_pop_width_m if pop else style.bubble_muzzle_width_m)

	sprite.position = position
	var camera := parent.get_viewport().get_camera_3d()
	if camera != null: sprite.position += camera.global_basis.z*style.art_camera_offset_m
	parent.add_child(sprite)
	active.append({"sprite":sprite,"start":tick,"duration":style.bubble_pop_ticks if pop else style.bubble_muzzle_ticks,"pop":pop})
	step(tick)

func step(tick: int) -> void:
	var alive: Array[Dictionary] = []
	for entry: Dictionary in active:
		var sprite: Sprite3D = entry.sprite
		var fraction: float = float(tick-entry.start)/entry.duration
		if fraction >= 1.0:
			sprite.queue_free()
			continue
		var eased: float = 1.0-pow(1.0-fraction,2)
		sprite.scale = Vector3.ONE*lerpf(0.40,1.20,eased)
		TOON_FX.advance(sprite,fraction)
		alive.append(entry)
	active = alive

func clear() -> void:
	for entry: Dictionary in active: (entry.sprite as Sprite3D).queue_free()
	active.clear()
