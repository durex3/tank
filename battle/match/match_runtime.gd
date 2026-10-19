extends RefCounted
class_name MatchRuntime
## Tick-batch adjudication; instances own frozen rules, roster and life deduplication.

enum Phase { REGULATION, OVERTIME, FINISHED }

var phase: Phase = Phase.REGULATION
var _rules: MatchRules
var _match_id: String
var _roster: Dictionary = {}
var _stats: Dictionary = {}
var _deaths: Dictionary = {}
var _scores: Array[int] = [0, 0]
var _deadline: int = 0
var _last_tick: int = 0
var _last_display: String = ""
var _winner: int = -1
var _reason: StringName = &""

func configure(id: String, rules: MatchRules, roster: Dictionary) -> String:
	if _rules != null:
		return "Match runtime is already configured"
	if id.is_empty() or rules == null:
		return "Missing match ID or rules"
	var errors := rules.validate()
	var counts: Array[int] = [0, 0]
	for entity: Variant in roster:
		if not roster[entity] is int:
			return "Invalid roster team type"
		var team: int = roster[entity]
		if not entity is int or entity <= 0 or team < 0 or team > 1:
			return "Invalid match roster"
		counts[team] += 1
	if not errors.is_empty() or counts != [rules.team_size, rules.team_size]:
		return "Invalid rules or incomplete roster"
	_match_id = id
	_rules = rules.duplicate(true) as MatchRules
	_roster = roster.duplicate()
	_deadline = _rules.duration_ticks
	for entity: int in _roster:
		_stats[entity] = {"kills": 0, "deaths": 0, "damage": 0}
	return ""

func commit_tick(tick: int, results: Array[Dictionary], events: BattleEvents) -> void:
	if _rules == null or phase == Phase.FINISHED or tick <= _last_tick:
		return
	_last_tick = tick
	for result: Dictionary in results:
		_record(result)
	_adjudicate(tick)
	var state := snapshot()
	var display := "%d:%d:%d:%d" % [phase, state.remaining_seconds, _scores[0], _scores[1]]
	if display != _last_display:
		_last_display = display
		events.publish(&"match_updated", tick, state)
	if phase == Phase.FINISHED:
		events.publish(&"match_finished", tick, state)

func snapshot() -> Dictionary:
	return {"match_id": _match_id, "phase": phase, "scores": _scores.duplicate(),
		"target_score": _rules.target_score, "remaining_seconds": ceili(float(maxi(0, _deadline - _last_tick)) / BattleClock.TICKS_PER_SECOND),
		"winner": _winner, "reason": _reason, "stats": _stats.duplicate(true)}

func _record(result: Dictionary) -> void:
	var target: int = result.target_id
	var source: int = result.source_id
	if result.get("training", true) or not _roster.has(target):
		return
	var key := "%d:%d" % [target, result.life_index]
	if _deaths.has(key):
		return
	var enemy: bool = _roster.has(source) and source != target and _roster[source] != _roster[target]
	if enemy:
		_stats[source].damage += result.actual_damage
	if not result.died:
		return
	_deaths[key] = true
	_stats[target].deaths += 1
	if enemy:
		_stats[source].kills += 1
		_scores[_roster[source]] += 1

func _adjudicate(tick: int) -> void:
	var tied: bool = _scores[0] == _scores[1]
	if phase == Phase.OVERTIME:
		if not tied:
			_finish(&"overtime_score")
		elif tick >= _deadline:
			_finish(&"overtime_draw")
		return
	if maxi(_scores[0], _scores[1]) < _rules.target_score and tick < _deadline:
		return
	if tied:
		phase = Phase.OVERTIME
		_deadline = tick + _rules.overtime_ticks
	else:
		_finish(&"target_score" if maxi(_scores[0], _scores[1]) >= _rules.target_score else &"time_limit")

func _finish(reason: StringName) -> void:
	phase = Phase.FINISHED
	_reason = reason
	_winner = -1 if _scores[0] == _scores[1] else (0 if _scores[0] > _scores[1] else 1)
