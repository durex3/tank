extends SceneTree
## Event-to-visual contract, resource alpha, pause and disposal regression.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var view := CombatView.new()
	view.style = view.style.duplicate() as CombatEffectStyle
	view.style.max_active = 2
	root.add_child(view)
	for texture: Texture2D in [view.style.muzzle, view.style.impact, view.style.explosion]:
		var image := texture.get_image()
		check(image.get_width() <= 512 and image.get_height() <= 512, "bounded source dimensions")
		check(image.detect_alpha() != Image.ALPHA_NONE, "effect keeps transparent background")
	view.on_event({"kind": &"fire_rejected"})
	check(view.get_child_count() == 0, "rejected fire creates no muzzle art")
	var center := Vector3(1, 0.78, -2)
	view.on_event({"kind": &"weapon_fired", "position": center})
	var muzzle := view.get_child(0) as Sprite3D
	check(muzzle.texture == view.style.muzzle and muzzle.position == center, "committed muzzle uses configured texture and world point")
	view.on_event({"kind": &"entity_died", "position": center})
	check((view.get_child(1) as Sprite3D).texture == view.style.explosion, "death selects explosion")
	view.on_event({"kind": &"projectile_hit", "position": center})
	check(view.get_child_count() == 2, "cosmetic effect cap enforced")
	view.set_paused(true)
	var before_scale := muzzle.scale
	var before_alpha := muzzle.modulate.a
	await create_timer(0.25).timeout
	check(muzzle.scale == before_scale and muzzle.modulate.a == before_alpha, "pause freezes scale and fade")
	view.set_paused(false)
	await create_timer(0.7).timeout
	await process_frame
	check(view.get_child_count() == 0, "completed effects dispose their nodes")
	view.on_event({"kind": &"projectile_hit", "position": center})
	check((view.get_child(0) as Sprite3D).texture == view.style.impact, "expired budget frees capacity for impact")
	view.free()
	await process_frame
	check(root.get_child_count() == 0, "exit releases running effects")
	print("COMBAT VIEW TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
