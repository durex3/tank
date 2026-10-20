extends SceneTree
## Reference-informed motion remains deterministic and owned by committed facts.
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error(reason)
func _run() -> void:
	var layer := SkillFlipbookEffects.new()
	root.add_child(layer)
	layer.on_event({"kind":&"ability_fired","ability":&"breach","projectile_id":66,"source_id":1,"yaw":PI/2,"tick":10})
	var hit := {"kind":&"damage_applied","tick":10,"ability_id":&"breach","actual_damage":240,"target_id":7,"source_id":1,"projectile_id":66,"position":Vector3.ZERO}
	layer.on_event(hit)
	layer.on_event(hit)
	check(layer._clips.size() == 2,"Duplicate hit must not duplicate contact or fragment group")
	var group: Node3D = layer._clips[1].node
	check(group.particles.size() == layer.style.debris_count+1,"Bounded separate fragments plus one dust layer")
	var center_fragment: Sprite3D = group.particles[1].node
	layer.on_event({"kind":&"tick","tick":16})
	check(center_fragment.position.x > 0 and center_fragment.position.y > 0,"Committed shot direction drives outward fragment flight")
	var frozen: Vector3 = center_fragment.position
	for i: int in range(3): await process_frame
	check(center_fragment.position == frozen,"No new tick means fragment gravity and drift freeze")
	layer.on_event({"kind":&"tick","tick":16})
	check(center_fragment.position == frozen,"Repeated tick must not integrate velocity twice")
	layer.on_event({"kind":&"entity_died","target_id":7,"tick":17})
	check(layer._clips.is_empty(),"Death clears all layers of the owned effect")
	layer.on_event({"kind":&"ability_fired","ability":&"breach","projectile_id":67,"source_id":1,"yaw":0.0,"tick":20})
	hit.tick = 20
	hit.projectile_id = 67
	layer.on_event(hit)
	layer.on_event({"kind":&"tick","tick":20+layer.style.debris_ticks})
	check(layer._clips.is_empty(),"Delayed dust and fragments expire on their committed boundary")
	check(hit.actual_damage == 240 and hit.position == Vector3.ZERO,"Visual motion cannot mutate damage facts")
	layer.free()
	await process_frame
	check(root.get_child_count() == 0,"No fragment or dust orphan remains")
	print("REFERENCE STYLE TESTS: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
