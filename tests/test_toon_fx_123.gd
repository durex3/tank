extends SceneTree
## Run locally after import: godot --headless --path . --script tests/test_toon_fx_123.gd

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

func _initialize() -> void:
	var first: Sprite3D = TOON_FX.create(&"flash",&"warm",0,1.0)
	var second: Sprite3D = TOON_FX.create(&"flash",&"warm",1,1.0)
	var a: ShaderMaterial = first.material_override
	var b: ShaderMaterial = second.material_override
	if a == b:
		_fail("Instances share lifetime material")
		return
	TOON_FX.advance(first,0.8)
	if not is_equal_approx(float(a.get_shader_parameter("life")),0.8) or not is_zero_approx(float(b.get_shader_parameter("life"))):
		_fail("Erosion leaked to another instance")
		return
	var layer := AbilitySignatureEffects.new()
	root.add_child(layer)
	layer.on_event({"kind":&"ability_fired","tick":10,"source_id":1,"ability":&"bubble","position":Vector3.ZERO})
	var sprite: Sprite3D = layer.bursts[0].sprites[0]
	layer.on_event({"kind":&"tick","tick":12})
	var material: ShaderMaterial = sprite.material_override
	var before: float = material.get_shader_parameter("life")
	layer.on_event({"kind":&"tick","tick":12})
	if not is_equal_approx(before,float(material.get_shader_parameter("life"))):
		_fail("Repeated committed tick advances life")
		return
	layer.on_event({"kind":&"entity_died","tick":12,"target_id":1})
	if not layer.bursts.is_empty():
		_fail("Dead owner retains ultimate burst")
		return
	layer.clear()
	var bubble := BubbleVisual.new()
	var tuning: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
	bubble.configure(1.4,0,true,tuning)
	var shot := ProjectileState.new()
	shot.kind = &"bubble_field"
	shot.radius = 1.4
	shot.spawn_tick = 0
	shot.lifetime_ticks = 180
	bubble.present(shot,160)
	if not is_equal_approx(bubble.film.pixel_size*bubble.film.texture.get_width(),shot.radius*2) or not is_equal_approx(bubble.film.modulate.a,1.0):
		_fail("Field boundary must match real diameter and stay readable before final fade")
		return
	bubble.present(shot,180)
	if not is_zero_approx(bubble.film.modulate.a) or not is_equal_approx(shot.radius,1.4):
		_fail("Expired field remains visible or presentation changes authoritative radius")
		return
	bubble.free()
	first.free()
	second.free()
	layer.queue_free()
	print("PASS toon material isolation / frozen tick / owner death cleanup")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
