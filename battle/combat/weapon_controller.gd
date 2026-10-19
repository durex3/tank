extends RefCounted
class_name WeaponController
## Single-shot/held-fire gate. IDs remain monotonic for this controller lease.

const REQUEST_WINDOW_TICKS: int = 6
var next_fire_tick: int = 0
var _last_request: int = 0
var _pending: int = 0
var _expires: int = 0

func poll(command: PlayerCommand, tick: int, interval: int, continuous: bool = false) -> Dictionary:
	if continuous:
		_pending = 0
		if not command.fire_held or tick < next_fire_tick:
			return {}
		next_fire_tick = tick + interval
		# Held shots have no discrete input request. Projectile IDs remain unique.
		return {"request_id": 0}
	if command.fire_request_id > _last_request:
		_last_request = command.fire_request_id
		_pending = _last_request
		_expires = command.client_tick + REQUEST_WINDOW_TICKS
	if _pending == 0:
		return {}
	if tick > _expires:
		_pending = 0
		return {"rejected": &"cooldown_expired"}
	if tick < next_fire_tick:
		return {}
	var request := _pending
	_pending = 0
	next_fire_tick = tick + interval
	return {"request_id": request}

func cancel_pending() -> void:
	_pending = 0
