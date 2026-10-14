extends SceneTree
## Real session commands, fixed snapshots at normal gameplay resolution.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280,720)
	for weapon: StringName in [&"cannon",&"autocannon",&"scatter",&"bubble_cannon"]:
		for ability: bool in [false,true]:
			var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
			assert(screen.session.configure_loadout(weapon,&"light_tracks").is_empty())
			root.add_child(screen)
			screen.session.set_physics_process(false)
			for frame: int in range(12): await physics_frame
			var session: MovementSession = screen.session
			if session.phase == MovementSession.Phase.PAUSED: session.resume()
			var sim: BattleSimulation = session.simulation
			var hits: Array[Dictionary] = []
			sim.events.published.connect(func(event: Dictionary) -> void:
				if event.kind == &"projectile_hit": hits.append(event))
			if not ability:
				var target: TrainingTarget = sim.targets[0]
				target.position = Vector3(0,0,-5)
				target.configure_motion(0,0)
				target.force_update_transform()
				await physics_frame
			var impact_saved: bool = false
			for step: int in range(1,206 if ability else 40):
				var command := PlayerCommand.new()
				command.session_epoch = sim.session_epoch
				command.sequence = sim.tick+1
				command.client_tick = sim.tick+1
				command.fire_request_id = 1 if not ability and step == 1 else 0
				command.fire_held = weapon == &"autocannon" and (not ability or step > 1)
				command.ability_request_id = 1 if ability and step == 1 else 0
				sim.enqueue_command(command)
				sim.step()
				if step in ([8,16,24,30,38,50,205] if ability else [2,5,8]):
					for frame: int in range(2): await process_frame
					screen.pause_overlay.dismiss()
					await RenderingServer.frame_post_draw
					var file: String = "res://artifacts/identity-%s-%s-%02d.png" % [weapon,"ability" if ability else "normal",step]
					assert(root.get_texture().get_image().save_png(file) == OK)
				if not ability and not impact_saved and not hits.is_empty():
					for frame: int in range(2): await process_frame
					screen.pause_overlay.dismiss()
					await RenderingServer.frame_post_draw
					assert(root.get_texture().get_image().save_png("res://artifacts/identity-%s-impact.png" % weapon) == OK)
					impact_saved = true
			session.stop()
			screen.free()
			await process_frame
	print("WEAPON IDENTITY CAPTURE: PASS")
	quit()
