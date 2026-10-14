extends SceneTree
## Physical motion regressions: heading controls autonomous speed, never forced displacement.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor := CharacterBody3D.new()
	root.add_child(actor)
	var motor := TankMotor.new()
	root.add_child(motor)
	var state := TankState.new()
	await physics_frame
	for tick: int in range(60):
		motor.step(actor, state, Vector2(0, -1), 6.0, 1.0 / 60.0)
		await physics_frame
	check(is_equal_approx(actor.velocity.length(), 6.0), "aligned travel reaches full speed")
	motor.step(actor, state, Vector2(0, 1), 6.0, 1.0 / 60.0, Vector3.ZERO, 1)
	check(actor.velocity.z < 0.0 and actor.velocity.length() < 5.5, "reversal brakes existing momentum immediately")
	for tick: int in range(9):
		await physics_frame
		motor.step(actor, state, Vector2(0, 1), 6.0, 1.0 / 60.0, Vector3.ZERO, 1)
	check(actor.velocity.length() < 1.2, "reversal keeps speed low while facing away")
	check(state.body_yaw > 0.0, "opposite turn follows explicit positive arc")
	for tick: int in range(50):
		await physics_frame
		motor.step(actor, state, Vector2(0, 1), 6.0, 1.0 / 60.0)
	check(actor.velocity.is_equal_approx(Vector3(0, 0, 6)), "reverse travel recovers full input direction speed")
	for tick: int in range(10):
		await physics_frame
		motor.step(actor, state, Vector2.ZERO, 6.0, 1.0 / 60.0)
	check(actor.velocity.is_zero_approx(), "release stops within ten ticks")
	motor.halt(actor, state)
	state.body_yaw = 0.0
	motor.step(actor, state, Vector2.RIGHT, 6.0, 1.0 / 60.0)
	check(actor.velocity.x > 0.0 and actor.velocity.x < 0.4, "perpendicular start respects requested direction with low speed")
	motor.halt(actor, state)
	var yaw: float = state.body_yaw
	motor.step(actor, state, Vector2.ZERO, 6.0, 1.0 / 60.0, Vector3(8, 0, 0))
	check(actor.velocity.is_equal_approx(Vector3(8, 0, 0)), "forced velocity bypasses alignment slowdown")
	check(is_equal_approx(yaw, state.body_yaw), "force alone does not steer hull")
	motor.halt(actor, state)
	check(actor.velocity.is_zero_approx() and state.velocity.is_zero_approx(), "halt clears movement state")
	actor.free()
	motor.free()
	print("STEERING FEEL TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
