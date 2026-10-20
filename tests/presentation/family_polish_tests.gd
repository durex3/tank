extends SceneTree
## Family feedback remains distinct, bounded, fact-driven and deterministic.
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error(reason)
func _run() -> void:
	var art := AbilitySpriteEffects.new()
	root.add_child(art)
	art.on_event({"kind":&"weapon_fired","tick":1,"source_id":1,"weapon":&"autocannon","position":Vector3.ZERO})
	art.on_event({"kind":&"tick","tick":4})
	check(art._effects.is_empty(),"Rapid muzzle clears before the next three-tick storm shot")
	art.on_event({"kind":&"weapon_fired","tick":5,"source_id":1,"weapon":&"scatter","position":Vector3.ZERO})
	check(int((art._effects[0].sprite.material_override as ShaderMaterial).get_shader_parameter("variant")) == 3,"Scatter uses its own wide fan contact")
	art.clear()
	var frame := SkillFlipbookEffects.new()
	root.add_child(frame)
	var state := {"kind":&"ability_state","tick":10,"source_id":1,"alive":true,"phase":&"dash","position":Vector3.ZERO,"yaw":0.0,"locked_yaw":PI/2,"body_yaw":PI/2,"cruise":false}
	frame.on_event(state)
	var dust: Node3D = frame._clips[0].node
	frame.on_event({"kind":&"tick","tick":14})
	check((dust.particles[0].node as Sprite3D).position.x < 0,"Dash dust follows locked dash direction even when aim differs")
	var frozen: Vector3 = dust.particles[0].node.position
	for i: int in range(3): await process_frame
	frame.on_event({"kind":&"tick","tick":14})
	check(dust.particles[0].node.position == frozen,"Motion is frozen without a new tick, including duplicate tick")
	frame.clear()
	state.tick = 24
	state.phase = &"idle"
	state.cruise = false
	frame.on_event(state)
	check(frame._clips.is_empty(),"Stationary chassis cannot invent reload accents")
	state.cruise = true
	frame.on_event(state)
	check(frame._clips.size() == 1,"One moving reload cue contains two constituent glints")
	state.tick = 25
	state.position = Vector3(3,0,0)
	frame.on_event(state)
	check(is_equal_approx(float(frame._clips[0].node.origin.x),3.0),"Reload glints follow committed chassis movement rather than leaving a speed trail")
	frame.clear()
	state.cruise = false
	state.tick = 25
	frame.on_event(state)
	var hit := {"kind":&"damage_applied","tick":25,"guarded":true,"target_id":1,"position":Vector3.ZERO}
	frame.on_event(hit)
	frame.on_event(hit)
	check(frame._clips.size() == 1,"Guard contact and deflection sparks deduplicate together")
	var sparks: Node3D = frame._clips[0].accents
	check((sparks.particles[0].velocity as Vector3).x > 0,"Guard deflection uses body facing rather than aim")
	frame.on_event({"kind":&"ability_state","tick":26,"source_id":1,"alive":false})
	check(frame._clips.is_empty(),"Owner death removes contact and all child sparks")
	var bursts := BubbleBursts.new()
	var tuning: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
	bursts.spawn(art,Vector3.ZERO,40,tuning,true)
	var drops: Node3D = bursts.active[0].droplets
	bursts.step(44)
	check(drops.particles.size() == 3 and drops.particles[0].node.position != drops.particles[2].node.position,"One splash has three distinct moving droplets")
	bursts.step(40+tuning.bubble_pop_ticks)
	check(bursts.active.is_empty(),"Water burst root and all droplets expire together")
	art.free()
	frame.free()
	await process_frame
	check(root.get_child_count() == 0,"All family accents leave no orphan nodes")
	print("FAMILY POLISH TESTS: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
