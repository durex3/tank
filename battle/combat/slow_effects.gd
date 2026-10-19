extends RefCounted
class_name SlowEffects
## Timed slows are committed only after final batch health, and start next tick.

var _entries: Dictionary = {}

func commit(results: Array[Dictionary], states: Array[DamageableState], tick: int) -> void:
	for state: DamageableState in states:
		var key: String = "%d:%d" % [state.entity_id,state.life_index]
		if state.hp <= 0:
			_entries.erase(key)
			continue
		for result: Dictionary in results:
			if result.target_id != state.entity_id or result.life_index != state.life_index: continue
			var duration: int = int(result.get("slow_ticks",0))
			var multiplier: float = float(result.get("slow_multiplier",1.0))
			if duration <= 0 or multiplier >= 1.0: continue
			if not _entries.has(key): _entries[key] = {}
			_entries[key][result.source_id] = {"start":tick+1,"until":tick+1+duration,"multiplier":multiplier}
	var valid: Dictionary = {}
	for state: DamageableState in states: valid["%d:%d" % [state.entity_id,state.life_index]] = state.hp > 0
	for key: String in _entries.keys():
		if not valid.get(key,false):
			_entries.erase(key)
			continue
		for source: int in _entries[key].keys():
			if tick >= _entries[key][source].until: _entries[key].erase(source)
		if _entries[key].is_empty(): _entries.erase(key)

func multiplier(state: DamageableState, tick: int) -> float:
	if state.hp <= 0: return 1.0
	var result: float = 1.0
	for entry: Dictionary in _entries.get("%d:%d" % [state.entity_id,state.life_index],{}).values():
		if tick >= entry.start and tick < entry.until: result = minf(result,entry.multiplier)
	return maxf(0.6,result)

func clear() -> void:
	_entries.clear()
