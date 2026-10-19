extends SceneTree
## Stable old-shot identity, directional silhouettes and committed-tick stage cleanup.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	await _identity()
	await _stages()
	print("WEAPON IDENTITY TESTS: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _identity() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var target := TrainingTarget.new()
	target.position = Vector3(0,0,-3)
	world.add_child(target)
	await physics_frame
	await physics_frame
	var space := world.get_world_3d().direct_space_state
	var shots := ProjectileSystem.new()
	var weapon := LoadoutCatalog.weapon(&"scatter").duplicate() as WeaponDef
	var shot: ProjectileState = shots.spawn(space,Vector3.ZERO,0,weapon,1,1,1)
	weapon.id = &"cannon"
	check(shot.weapon_id == &"scatter","old shot freezes originating weapon despite source definition changes")
	for tick: int in range(2,20): shots.step(space,tick)
	check(not shots.impacts.is_empty() and shots.impacts[0].weapon == &"scatter","impact preserves old-shot identity after flight")
	check(shots.impacts[0].direction == Vector3.FORWARD,"impact retains committed direction")
	var view := CombatView.new()
	view.projectiles = ProjectileSystem.new()
	root.add_child(view)
	var id: int = 10
	for kind: StringName in [&"cannon",&"autocannon",&"scatter",&"bubble_cannon"]:
		var sample := ProjectileState.new()
		sample.projectile_id = id
		sample.weapon_id = kind
		sample.direction = Vector3.RIGHT
		sample.position = Vector3(7,0.78,4)
		if kind == &"bubble_cannon":
			sample.kind = &"bubble_round"
			sample.radius = 0.25
		view.projectiles.active.append(sample)
		id += 1
	view._process(0)
	check(view._visuals[10].get_child_count() != view._visuals[11].get_child_count(),"shell and needle have different 3D silhouette assemblies")
	for i: int in [2,3]:
		var trail := view._visuals[10].get_child(i) as MeshInstance3D
		check((trail.basis*Vector3.UP).is_equal_approx(Vector3.BACK),"both glow planes extend behind shell, never form crossed projectiles")
	check((view._visuals[12].get_child(0) as MeshInstance3D).mesh is PrismMesh,"scatter uses angular fragments")
	check(view._visuals[13] is BubbleVisual,"bubble remains translucent film rather than a solid bullet")
	for sample: ProjectileState in view.projectiles.active:
		check(sample.position == Vector3(7,0.78,4) and sample.damage == 0,"presentation does not mutate authority")
		if sample.kind != &"bubble_round":
			check((view._visuals[sample.projectile_id].basis*Vector3.FORWARD).is_equal_approx(Vector3.RIGHT),"solid projectile silhouettes face nonzero travel direction")
		else:
			var bubble: BubbleVisual = view._visuals[sample.projectile_id]
			check(bubble.trail.position.dot(sample.direction) < 0,"camera-facing bubble companion trails behind committed direction")
	view.free()
	world.free()
	await process_frame

func _stages() -> void:
	var signatures := AbilitySignatureEffects.new()
	root.add_child(signatures)
	signatures.style = signatures.style.duplicate() as WeaponVisualStyle
	signatures.style.max_signatures = 2
	var event := {"kind":&"ability_fired","tick":1,"source_id":1,"ability":&"shock","position":Vector3.ZERO,"yaw":PI/2}
	signatures.on_event(event)
	signatures.on_event(event)
	check(signatures.bursts.size() == 1,"duplicate committed release cannot stack a second wave")
	signatures.on_event({"kind":&"ability_zones","tick":2})
	var sprite: Sprite3D = signatures.bursts[0].sprites[0]
	check(sprite.pixel_size*1024 <= signatures.rules.shock_range*2,"skill puff remains bounded by range")
	var material: ShaderMaterial = sprite.material_override
	var frozen: float = material.get_shader_parameter("life")
	for i: int in range(3): await process_frame
	check(is_equal_approx(float(material.get_shader_parameter("life")),frozen),"no committed tick freezes erosion")
	for i: int in range(2,6):
		var other: Dictionary = event.duplicate()
		other.source_id = i
		other.tick = 2
		signatures.on_event(other)
	check(signatures.bursts.size() == 2,"release geometry respects cosmetic overload cap")
	var state := {"kind":&"ability_state","tick":2,"source_id":1,"phase":&"breach","alive":true,"position":Vector3.ZERO,"yaw":PI/2,"body_yaw":0.0,"remaining":10}
	signatures.on_event(state)
	check(signatures.actors.has(1),"committed preparation creates source-scoped signature")
	state.alive = false
	signatures.on_event(state)
	check(not signatures.actors.has(1),"death removes only that actor's preparation")
	signatures.on_event({"kind":&"ability_zones","tick":30})
	check(signatures.bursts.is_empty(),"release waves expire by committed tick")
	signatures.on_event(event)
	check(signatures.bursts.is_empty(),"stale prior-tick releases cannot replay after expiry")
	signatures.on_event({"kind":&"match_finished","tick":31})
	check(signatures.actors.is_empty() and signatures.bursts.is_empty(),"finished session clears signature ownership")
	signatures.on_event({"kind":&"ability_fired","tick":40,"source_id":1,"ability":&"breach","position":Vector3.ZERO,"end":Vector3.FORWARD*10,"yaw":0.0})
	check(signatures.bursts.size() == 1,"energy cannon creates one committed release")
	var energy: ShaderMaterial = signatures.bursts[0].material
	var peak: float = energy.get_shader_parameter("life")
	signatures.on_event({"kind":&"ability_zones","tick":47})
	check(float(energy.get_shader_parameter("life")) > peak,"energy blast contracts after its initial peak")
	signatures.on_event({"kind":&"ability_zones","tick":54})
	check(signatures.bursts.is_empty(),"energy blast expires after fourteen ticks")
	signatures.free()
	await process_frame
	check(root.get_child_count() == 0,"new visual owners dispose completely")
