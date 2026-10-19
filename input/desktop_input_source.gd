extends InputSource
class_name DesktopInputSource
## InputMap adapter. Mouse ground direction is injected by session service.

var continuous_fire: bool = false
var _fire_contacts: Dictionary = {}
var session_epoch: int = 0
var aim_distance_cm: int = 600
var aim_direction: Vector2 = Vector2.UP
var _enabled: bool = true
var _focused: bool = true
var _blocked_actions: Dictionary = {}
var _sequence: int = 0
var _request_id: int = 0
var _pending_fire: int = 0
var _pressed: bool = false
var _ability_id: int = 0
var _pending_ability: int = 0

func sample(tick: int) -> PlayerCommand:
	_sequence += 1
	var command := PlayerCommand.new()
	command.session_epoch = session_epoch
	command.sequence = _sequence
	command.client_tick = tick
	if not _enabled or not _focused:
		return command
	var move := Vector2(_strength(&"move_right") - _strength(&"move_left"), _strength(&"move_down") - _strength(&"move_up")).limit_length(1.0)
	command.move_x = roundi(move.x * 127.0)
	command.move_z = roundi(move.y * 127.0)
	command.turn_preference = signi(command.move_x)
	command.aim_yaw = roundi(fposmod(atan2(aim_direction.x, -aim_direction.y), TAU) / TAU * 65536.0) % 65536
	command.aim_distance_cm = aim_distance_cm
	command.fire_held = continuous_fire and not _fire_contacts.is_empty()
	command.ability_request_id = _pending_ability
	_pending_ability = 0
	command.fire_request_id = _pending_fire
	_pending_fire = 0
	return command

func handle_event(event: InputEvent) -> void:
	if not _enabled or not _focused or event.is_echo():
		return
	if event is InputEventMouseButton and event.device == -1:
		return
	if event is InputEventKey and ((event as InputEventKey).physical_keycode == KEY_Q or (event as InputEventKey).keycode == KEY_Q) and event.is_pressed():
		request_ability()
	var contact := _fire_contact(event)
	if event.is_action_pressed("fire"):
		_fire_contacts[contact] = true
		_pressed = true
	elif event.is_action_released("fire") and _fire_contacts.has(contact):
		_fire_contacts.erase(contact)
		if not continuous_fire and _pressed:
			_request_id += 1
			_pending_fire = _request_id
		_pressed = not _fire_contacts.is_empty()

func _fire_contact(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		return "mouse:%d" % (event as InputEventMouseButton).button_index
	if event is InputEventKey:
		var key := event as InputEventKey
		return "key:%d" % (key.physical_keycode if key.physical_keycode != 0 else key.keycode)
	return "action:fire"

func set_enabled(value: bool) -> void:
	cancel_pending()
	_enabled = value
	if value:
		_block_held_movement()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_focused = false
		cancel_pending()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_focused = true
		cancel_pending()
		_block_held_movement()

func cancel_pending() -> void:
	_pending_ability = 0
	_fire_contacts.clear()
	_pending_fire = 0
	_pressed = false

func _block_held_movement() -> void:
	_blocked_actions.clear()
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if Input.is_action_pressed(action):
			_blocked_actions[action] = true

func _strength(action: StringName) -> float:
	if _blocked_actions.has(action):
		if not Input.is_action_pressed(action):
			_blocked_actions.erase(action)
		return 0.0
	return Input.get_action_strength(action)

func request_ability() -> void:
	if _enabled and _focused:
		_ability_id += 1
		_pending_ability = _ability_id
