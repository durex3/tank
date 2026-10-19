extends SceneTree
## Verify independent moving parts and preserve authority across all new modules.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for weapon: StringName in [&"autocannon", &"scatter", &"bubble_cannon"]:
		var view := TankView.new()
		root.add_child(view)
		assert(view.configure_parts(weapon, &"light_tracks").is_empty())
		var pivot := view.find_child("RecoilPivot", true, false) as Node3D
		assert(pivot != null)
		var rest := pivot.position
		var authority := view.muzzle_transform()
		var visual := view.visual_muzzle_position()
		view.on_event({"kind": &"weapon_fired", "source_id": 0, "weapon": weapon, "tick": 10})
		view.advance_visual_tick(11)
		assert(not pivot.position.is_equal_approx(rest))
		assert(not view.visual_muzzle_position().is_equal_approx(visual))
		assert(view.muzzle_transform().is_equal_approx(authority))
		var peak := pivot.position
		view.advance_visual_tick(11)
		assert(pivot.position.is_equal_approx(peak))
		view.advance_visual_tick(40)
		assert(pivot.position.is_equal_approx(rest))
		view.free()
	for chassis: StringName in [&"scout_wheels", &"heavy_tracks"]:
		var view := TankView.new()
		root.add_child(view)
		assert(view.configure_parts(&"cannon", chassis).is_empty())
		var wheels := view.find_children("Wheel*", "Node3D", true, false)
		assert(wheels.size() == (4 if chassis == &"scout_wheels" else 8))
		var state := TankState.new()
		view.present(state)
		view.advance_visual_tick(0)
		state.position.z = -0.2
		view.present(state)
		view.advance_visual_tick(1)
		var wheel := wheels[0] as Node3D
		assert(absf(wheel.rotation.x) > 0.1)
		var angle := wheel.rotation.x
		view.advance_visual_tick(1)
		assert(is_equal_approx(wheel.rotation.x, angle))
		view.reset_visual_motion()
		assert(is_zero_approx(wheel.rotation.x))
		view.free()
	print("FAMILY MOTION: PASS")
	quit()
