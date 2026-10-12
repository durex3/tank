extends SceneTree
## Real simulation and Compatibility render; no profile mutation.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280,720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	assert(screen.session.configure_loadout(&"bubble_cannon",&"light_tracks").is_empty())
	root.add_child(screen)
	screen.session.set_physics_process(false)
	for i: int in range(8): await process_frame
	await physics_frame
	var sim: BattleSimulation = screen.session.simulation
	for i: int in range(1,30):
		var command := PlayerCommand.new()
		command.session_epoch = sim.session_epoch
		command.client_tick = sim.tick+1
		command.sequence = sim.tick+1
		command.ability_request_id = 1 if i == 1 else 0
		sim.enqueue_command(command)
		sim.step()
		if i in [10,24]:
			for j: int in range(3): await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("res://artifacts/bubble-"+str(i)+".png") == OK)
	for tick: int in range(30,188):
		var command := PlayerCommand.new()
		command.session_epoch = sim.session_epoch
		command.client_tick = sim.tick+1
		command.sequence = sim.tick+1
		command.fire_request_id = tick if tick in [70,109,148,187] else 0
		sim.enqueue_command(command)
		sim.step()
		if tick in [80,187]:
			for j: int in range(3): await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("res://artifacts/bubble-"+str(tick)+".png") == OK)
	var target: TrainingTarget = sim.targets[0]
	target.position = Vector3(0,0,-3)
	target.configure_motion(0,0)
	target.force_update_transform()
	await physics_frame
	var contact := PlayerCommand.new()
	contact.session_epoch = sim.session_epoch
	contact.client_tick = sim.tick+1
	contact.sequence = sim.tick+1
	sim.enqueue_command(contact)
	sim.step()
	for i: int in range(2):
		var neutral := PlayerCommand.new()
		neutral.session_epoch = sim.session_epoch
		neutral.client_tick = sim.tick+1
		neutral.sequence = sim.tick+1
		sim.enqueue_command(neutral)
		sim.step()
	for j: int in range(3): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/bubble-pop.png") == OK)
	screen.session.stop()
	screen.queue_free()
	await process_frame
	var hangar := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	root.add_child(hangar)
	for i: int in range(5): await process_frame
	hangar.weapon_picker.select(3)
	hangar.weapon_picker.item_selected.emit(3)
	for i: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/bubble-hangar.png") == OK)
	hangar.queue_free()
	await process_frame
	print("BUBBLE CAPTURE: PASS")
	quit()
