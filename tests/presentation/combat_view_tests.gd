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
	await _test_bubble_visuals()
	print("COMBAT VIEW TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_bubble_visuals() -> void:
	var view := CombatView.new()
	view.ability_style = view.ability_style.duplicate() as AbilityEffectStyle
	view.ability_style.bubble_max_bursts = 2
	view.projectiles = ProjectileSystem.new()
	root.add_child(view)
	for texture: Texture2D in [view.ability_style.bubble_film,view.ability_style.bubble_splash]:
		var image := texture.get_image()
		check(image.get_size() == Vector2i(512,512) and image.detect_alpha() != Image.ALPHA_NONE,"bubble art has bounded RGBA textures")
	check(view.ability_style.bubble_film.get_image().get_pixel(256,256).a < 0.25,"bubble film center remains see-through")
	var shot := ProjectileState.new()
	shot.projectile_id = 1
	shot.kind = &"bubble_barrier"
	shot.position = Vector3(0,0.78,0)
	shot.radius = 0.45
	shot.spawn_tick = 10
	shot.lifetime_ticks = 180
	view.projectiles.active.append(shot)
	view.on_event({"kind":&"ability_state","tick":10})
	await process_frame
	await process_frame
	var bubble := view._visuals[1] as BubbleVisual
	check(bubble != null and bubble.film.texture == view.ability_style.bubble_film,"authoritative bubble creates generated film visual")
	view.on_event({"kind":&"ability_state","tick":16})
	await process_frame
	var position_before := bubble.film.position
	var scale_before := bubble.film.scale
	view.set_paused(true)
	view.on_event({"kind":&"ability_state","tick":50})
	await create_timer(0.15).timeout
	check(bubble.film.position == position_before and bubble.film.scale == scale_before,"paused bubble wobble and expansion freeze")
	view.set_paused(false)
	for i: int in range(3): view.on_event({"kind":&"projectile_hit","tick":20,"bubble":true,"position":shot.position})
	check(view._bubble_bursts.active.size() == 2,"burst budget drops only cosmetic overload")
	view.on_event({"kind":&"ability_state","tick":34})
	await process_frame
	check(view._bubble_bursts.active.is_empty(),"burst expires at committed tick boundary")
	view.on_event({"kind":&"weapon_fired","tick":35,"weapon":&"bubble_cannon","position":shot.position})
	check(view._bubble_bursts.active.size() == 1,"bubble muzzle uses film instead of gunfire art")
	view.on_event({"kind":&"match_finished","tick":36})
	check(view._bubble_bursts.active.is_empty(),"match completion clears droplets")
	view.free()
	await process_frame
	check(root.get_child_count() == 0,"bubble presentation and all field-only nodes dispose")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
