extends RefCounted
class_name BattleEvents
## Scoped to a single session. UI and effects consume committed facts.

signal published(event: Dictionary)

var match_id: String = "local_training"
var _event_id: int = 0

func publish(kind: StringName, tick: int, payload: Dictionary = {}) -> void:
	_event_id += 1
	var event := payload.duplicate()
	event.merge({"kind": kind, "tick": tick, "match_id": match_id, "event_id": _event_id,
		"source_id": payload.get("source_id", 0), "target_id": payload.get("target_id", 0)}, true)
	published.emit(event)
