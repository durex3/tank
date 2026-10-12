extends SceneTree
## Feedback follows committed facts and remains bounded, pausable and directionally correct.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	var art := AbilitySpriteEffects.new()
	root.add_child(art)
	art.on_event({"kind":&"damage_applied","tick":1,"guarded":false,"position":Vector3.ZERO})
	check(art._messages.is_empty(),"unguarded damage cannot announce a block")
	art.on_event({"kind":&"damage_applied","tick":2,"guarded":true,"position":Vector3.ZERO})
	check(art._messages.size() == 1,"actual guarded fact creates one block notice")
	var label: Label3D = art._messages[0].label
	var position_before := label.position
	var opacity_before: float = label.modulate.a
	for i: int in range(4): await process_frame
	check(label.position == position_before and label.modulate.a == opacity_before,"no committed ticks means feedback stays frozen")
	for count: int in [1,2]:
		art.on_event({"kind":&"damage_applied","tick":3,"position":Vector3.ZERO,"target_id":7,"bubble_hits":count})
	check(art._messages.size() == 2 and (art._messages[1].label as Label3D).text.contains("2/2"),"same-tick bubble contacts show one final hit-cap label")
	art.on_event({"kind":&"ability_zones","tick":40,"zones":[]})
	check(art._messages.is_empty() and art._effects.is_empty(),"old block notice and sparkle expire by tick")
	var zones: Array = []
	for i: int in range(20): zones.append({"owner_id":i,"position":Vector3(i,0,0),"until_tick":200})
	art.on_event({"kind":&"ability_zones","tick":50,"zones":zones})
	var count: int = 0
	for cloud: Array in art._smoke.values(): count += cloud.size()
	check(count <= art.style.max_smoke_sprites and count > art._smoke.size(),"smoke has multiple layers with a global sprite cap")
	art.style = art.style.duplicate() as AbilityEffectStyle
	art.style.max_smoke_sprites = 7
	zones.reverse()
	art.on_event({"kind":&"ability_zones","tick":51,"zones":zones})
	count = 0
	for cloud: Array in art._smoke.values(): count += cloud.size()
	check(count <= 7,"non-divisible smoke budget remains bounded when zone order changes")
	art.on_event({"kind":&"ability_zones","tick":52,"zones":[]})
	check(art._smoke.is_empty(),"cleared or dead-owner zones release all cloud layers")
	var state := {"kind":&"ability_state","tick":60,"source_id":1,"alive":true,"phase":&"breach","remaining":12,"position":Vector3.ZERO,"yaw":0.0}
	art.on_event(state)
	check(art._charge.size() == 1,"committed charge state creates a persistent core")
	state = state.duplicate()
	state.source_id = 2
	art.on_event(state)
	check(art._charge.size() == 2,"charge visuals stay independent per actor")
	state.alive = false
	art.on_event(state)
	check(not art._charge.has(2) and art._charge.has(1),"death removes only its own charge")
	state.source_id = 1
	state.alive = true
	state.phase = &"idle"
	art.on_event(state)
	check(art._charge.is_empty(),"launch removes charge core")
	art.on_event({"kind":&"ability_started","tick":61,"source_id":1,"phase":&"storm"})
	art.on_event({"kind":&"weapon_fired","tick":61,"source_id":1,"position":Vector3.ZERO})
	art.on_event({"kind":&"weapon_fired","tick":61,"source_id":2,"position":Vector3.ZERO})
	var boosted: Sprite3D = art._effects[0].sprite
	var ordinary: Sprite3D = art._effects[1].sprite
	check(boosted.pixel_size > ordinary.pixel_size,"first storm shot has stronger muzzle art than ordinary fire")
	state.source_id = 1
	state.phase = &"cooling"
	state.tick = 62
	art.on_event(state)
	check(art._heat.size() == 1 and art._heat[1].size() == 2,"red heat owns two bounded smoke plumes")
	var plume: Sprite3D = art._heat[1][0]
	var frozen_position: Vector3 = plume.position
	for i: int in range(3): await process_frame
	check(plume.position == frozen_position,"red heat smoke freezes without committed ticks")
	state.phase = &"idle"
	state.tick = 63
	art.on_event(state)
	check(art._heat.is_empty(),"red heat end removes persistent smoke")
	art.clear()
	art.on_event({"kind":&"ability_fired","tick":70,"source_id":1,"ability":&"shock","position":Vector3.ZERO,"yaw":PI/2})
	var wave: MeshInstance3D = art._effects[0].sprite
	check((wave.basis*Vector3.FORWARD).normalized().is_equal_approx(Vector3.RIGHT),"shock plane faces committed nonzero yaw")
	for tick: int in range(71,88):
		art.on_event({"kind":&"ability_zones","tick":tick,"zones":[]})
		check(wave.scale.x <= 1.0,"dust never expands beyond configured sector plane")
	art.on_event({"kind":&"match_finished","tick":88})
	check(art._effects.is_empty() and art._charge.is_empty() and art._phases.is_empty(),"match end clears all feedback owners")
	art.style = art.style.duplicate() as AbilityEffectStyle
	art.style.max_sprites = 2
	for i: int in range(10): art.on_event({"kind":&"projectile_hit","tick":90,"position":Vector3.ZERO})
	check(art._effects.size() == 2,"burst overload drops only extra visuals")
	art.clear()
	art.free()
	await process_frame
	_test_projectile_direction()
	await process_frame
	check(root.get_child_count() == 0,"feedback disposal leaves no scene owners")
	print("ABILITY VFX TESTS: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_projectile_direction() -> void:
	var view := CombatView.new()
	var shots := ProjectileSystem.new()
	var shot := ProjectileState.new()
	shot.projectile_id = 7
	shot.direction = Vector3.RIGHT
	shot.position = Vector3(4,0.78,2)
	shot.ability_damage = true
	shot.pierce_damage = PackedInt32Array([240,144,86])
	shots.active.append(shot)
	view.projectiles = shots
	root.add_child(view)
	view._process(0)
	var trail: Node3D = view._visuals[7]
	check((trail.basis*Vector3.FORWARD).normalized().is_equal_approx(shot.direction),"breach core faces travel direction")
	check((trail.basis*Vector3.BACK).normalized().dot(shot.direction) < -0.99,"breach tail trails behind the projectile")
	check(shot.position == Vector3(4,0.78,2),"visual assembly never shifts the authoritative projectile")
	var tracer := ProjectileState.new()
	tracer.projectile_id = 8
	tracer.direction = Vector3.RIGHT
	tracer.position = Vector3(1,0.78,3)
	tracer.storm_round = true
	shots.active.append(tracer)
	view._process(0)
	var tracer_view: Node3D = view._visuals[8]
	check((tracer_view.basis*Vector3.FORWARD).normalized().is_equal_approx(Vector3.RIGHT),"storm tracer follows nonzero travel direction")
	check(tracer.position == Vector3(1,0.78,3) and tracer.radius == 0,"larger tracer never changes collision or position")
	view.free()
