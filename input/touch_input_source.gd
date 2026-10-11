extends InputSource
class_name TouchInputSource
## Device adapter. Only actual ScreenTouch/ScreenDrag events enter touch state.

signal state_changed

var state := TouchInputState.new()
var viewport_to_logical: Transform2D = Transform2D.IDENTITY
var session_epoch: int = 0

func _input(event: InputEvent) -> void:
	handle_event(event)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		cancel_pending()

func _exit_tree() -> void:
	cancel_pending()

func handle_event(event: InputEvent) -> bool:
	var handled: bool = false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var point := viewport_to_logical * touch.position
		# canceled has priority even if a platform reports pressed=true.
		if touch.canceled:
			handled = state.release(touch.index, point, true)
		elif touch.pressed:
			handled = state.press(touch.index, point)
		else:
			handled = state.release(touch.index, point)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		handled = state.drag(drag.index, viewport_to_logical * drag.position)
	if handled:
		state_changed.emit()
	return handled

func sample(tick: int) -> PlayerCommand:
	return state.sample(tick, session_epoch)

func cancel_pending() -> void:
	state.cancel_pending()
	state_changed.emit()

func set_enabled(value: bool) -> void:
	state.set_enabled(value)
	state_changed.emit()

func set_continuous_fire(value: bool) -> void:
	cancel_pending()
	state.continuous_fire = value
