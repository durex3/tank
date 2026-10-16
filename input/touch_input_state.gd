extends RefCounted
class_name TouchInputState
## Logical-coordinate touch ownership. No scene or device APIs.

enum Slot { MOVE, AIM, ABILITY }

var tuning: TouchInputTuning = preload("res://content/input/default_touch.tres")
var continuous_fire: bool = false
var move_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.UP
var aim_distance_cm: int = 600
var aim_drag: Vector2 = Vector2.ZERO
var ability_drag: Vector2 = Vector2.ZERO
var enabled: bool = true
var _regions: Array[Rect2] = []
var _owners: Dictionary = {}
var _contacts: Dictionary = {}
var _canceled: Dictionary = {}
var _fire_id: int = 0
var _ability_id: int = 0
var _pending_fire: int = 0
var _pending_ability: int = 0
var _sequence: int = 0

func configure(regions: Array[Rect2]) -> void:
	assert(regions.size() == 3, "Expected move, aim and ability regions")
	cancel_pending()
	_regions = regions.duplicate()

func press(index: int, position: Vector2) -> bool:
	if not enabled or index < 0 or not position.is_finite() or _contacts.has(index):
		return false
	for slot: int in range(_regions.size()):
		if _regions[slot].has_point(position) and not _owners.has(slot):
			_owners[slot] = index
			_contacts[index] = slot
			drag(index, position)
			return true
	return false

func drag(index: int, position: Vector2) -> bool:
	if not _contacts.has(index) or not position.is_finite():
		return false
	var slot: int = _contacts[index]
	var raw := (position - _regions[slot].get_center()) / tuning.radius
	# A deliberate upward drag cancels an attack. Returning restores preview.
	_canceled[slot] = slot != Slot.MOVE and raw.y < -tuning.cancel_distance_radii
	var stick := apply_deadzone(raw)
	match slot:
		Slot.MOVE:
			move_vector = stick
		Slot.AIM:
			aim_drag = stick
			if stick.length() > 0.1: aim_distance_cm = clampi(roundi(stick.length()*900),200,900)
			if not stick.is_zero_approx() and not is_canceled(slot):
				aim_vector = stick.normalized()
		Slot.ABILITY:
			ability_drag = stick
			if not stick.is_zero_approx() and not is_canceled(slot):
				aim_vector = stick.normalized()
	return true

func release(index: int, position: Vector2, canceled: bool = false) -> bool:
	if not _contacts.has(index):
		return false
	if not position.is_finite():
		canceled = true
	else:
		drag(index, position)
	var slot: int = _contacts[index]
	if not canceled and not is_canceled(slot):
		if slot == Slot.AIM and not continuous_fire:
			_fire_id += 1
			_pending_fire = _fire_id
		elif slot == Slot.ABILITY:
			_ability_id += 1
			_pending_ability = _ability_id
	_clear_slot(slot, index)
	return true

func sample(tick: int, epoch: int = 0) -> PlayerCommand:
	_sequence += 1
	var command := PlayerCommand.new()
	command.session_epoch = epoch
	command.sequence = _sequence
	command.client_tick = tick
	command.move_x = roundi(move_vector.x * 127.0)
	command.move_z = roundi(move_vector.y * 127.0)
	# XZ yaw: 0 points toward -Z, positive rotates toward +X.
	command.aim_distance_cm = aim_distance_cm
	command.aim_yaw = roundi(fposmod(atan2(aim_vector.x, -aim_vector.y), TAU) / TAU * 65536.0) % 65536
	command.fire_held = (enabled and continuous_fire and _owners.has(Slot.AIM)
		and not aim_drag.is_zero_approx() and not is_canceled(Slot.AIM))
	command.fire_request_id = _pending_fire
	command.ability_request_id = _pending_ability
	_pending_fire = 0
	_pending_ability = 0
	return command

func cancel_pending() -> void:
	_owners.clear()
	_contacts.clear()
	_canceled.clear()
	move_vector = Vector2.ZERO
	aim_drag = Vector2.ZERO
	ability_drag = Vector2.ZERO
	_pending_fire = 0
	_pending_ability = 0

func set_enabled(value: bool) -> void:
	cancel_pending()
	enabled = value

func is_captured(slot: int) -> bool:
	return _owners.has(slot)

func is_canceled(slot: int) -> bool:
	return _canceled.get(slot, false)

func apply_deadzone(raw: Vector2) -> Vector2:
	var magnitude := minf(raw.length(), 1.0)
	if magnitude <= tuning.deadzone:
		return Vector2.ZERO
	return raw.normalized() * ((magnitude - tuning.deadzone) / (1.0 - tuning.deadzone))

func _clear_slot(slot: int, index: int) -> void:
	_owners.erase(slot)
	_contacts.erase(index)
	_canceled.erase(slot)
	match slot:
		Slot.MOVE:
			move_vector = Vector2.ZERO
		Slot.AIM:
			aim_drag = Vector2.ZERO
		Slot.ABILITY:
			ability_drag = Vector2.ZERO
