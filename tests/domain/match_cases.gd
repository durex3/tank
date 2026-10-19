extends RefCounted
## Pure rule edge cases, called by the match integration suite.

var errors := PackedStringArray()
var seen: Array[Dictionary] = []

func run() -> PackedStringArray:
	_test_validation()
	_test_timing()
	_test_batch_and_stats()
	_test_overtime()
	return errors

func _test_validation() -> void:
	var rules := MatchRules.new()
	check(rules.validate().is_empty(), "standard rules valid")
	rules.target_score = 0
	check(not rules.validate().is_empty(), "zero score rejected")
	rules.target_score = 20
	rules.friendly_fire = true
	check(not rules.validate().is_empty(), "unsupported friendly fire rejected")
	rules.friendly_fire = false
	check(not MatchRuntime.new().configure("bad", rules, {1: 0, 2: 1}).is_empty(), "incomplete standard roster rejected")
	rules.team_size = 1
	check(not MatchRuntime.new().configure("bad", rules, {1: 0, 2: 3}).is_empty(), "invalid team rejected")
	var runtime := MatchRuntime.new()
	check(runtime.configure("frozen", rules, {1: 0, 2: 1}).is_empty(), "duel roster accepted")
	rules.duration_ticks = 1
	runtime.commit_tick(1, [], _events())
	check(runtime.phase == MatchRuntime.Phase.REGULATION, "runtime freezes source resource")
	check(not runtime.configure("again", rules, {1: 0, 2: 1}).is_empty(), "runtime cannot reconfigure")

func _test_timing() -> void:
	var runtime := _runtime()
	var events := _events()
	runtime.commit_tick(1, [], events)
	check(runtime.snapshot().remaining_seconds == 2, "timer rounds up remaining ticks")
	runtime.commit_tick(119, [_kill(2, 1, 0)], events)
	check(runtime.phase == MatchRuntime.Phase.REGULATION, "below target before deadline continues")
	runtime.commit_tick(120, [], events)
	check(runtime.phase == MatchRuntime.Phase.FINISHED and runtime.snapshot().winner == 0, "time limit chooses leader")
	var ended := _count(&"match_finished")
	runtime.commit_tick(121, [_kill(1, 2, 0)], events)
	check(_count(&"match_finished") == ended and runtime.snapshot().scores == [1, 0], "finished runtime rejects later results and duplicate finish")
	var copy := runtime.snapshot()
	copy.scores[0] = 99
	copy.stats[1].kills = 99
	check(runtime.snapshot().scores[0] == 1 and runtime.snapshot().stats[1].kills == 1, "snapshot cannot mutate authority")
	runtime = _runtime()
	runtime.commit_tick(120, [_kill(2, 1, 0)], events)
	check(runtime.snapshot().winner == 0, "deadline tick includes committed kill")

func _test_batch_and_stats() -> void:
	var runtime := _runtime()
	var events := _events()
	var kill := _kill(2, 1, 0)
	runtime.commit_tick(1, [kill, kill], events)
	runtime.commit_tick(2, [kill], events)
	check(runtime.snapshot().scores == [1, 0] and runtime.snapshot().stats[1].damage == 120, "life death deduplicates across batches and damage is actual")
	runtime.commit_tick(3, [_kill(2, 1, 1)], events)
	check(runtime.snapshot().scores == [2, 0] and runtime.snapshot().reason == &"target_score", "new life can score and target ends match")
	runtime = _runtime()
	var training := _kill(2, 1, 0)
	training.training = true
	runtime.commit_tick(1, [training, _kill(100, 1, 0), _kill(1, 1, 0)], events)
	check(runtime.snapshot().scores == [0, 0], "training, unknown target and self destruction give no score")
	runtime.commit_tick(2, [_kill(2, 999, 0)], events)
	check(runtime.snapshot().scores == [0, 0], "unknown source gives no score")
	var rules := MatchRules.new()
	rules.team_size = 2
	runtime = MatchRuntime.new()
	runtime.configure("friendly", rules, {1: 0, 3: 0, 2: 1, 4: 1})
	runtime.commit_tick(1, [_kill(3, 1, 0)], events)
	check(runtime.snapshot().scores == [0, 0], "friendly death gives no team credit")

func _test_overtime() -> void:
	var runtime := _runtime(1)
	var events := _events()
	runtime.commit_tick(1, [_kill(2, 1, 0), _kill(1, 2, 0)], events)
	check(runtime.phase == MatchRuntime.Phase.OVERTIME and runtime.snapshot().scores == [1, 1], "same tick target tie enters overtime")
	runtime.commit_tick(2, [_kill(1, 2, 1), _kill(2, 1, 1)], events)
	check(runtime.phase == MatchRuntime.Phase.OVERTIME, "overtime mutual kill stays tied")
	runtime.commit_tick(3, [_kill(2, 1, 2)], events)
	check(runtime.snapshot().winner == 0 and runtime.snapshot().reason == &"overtime_score", "first untied overtime batch wins")
	runtime = _runtime()
	runtime.commit_tick(120, [], events)
	check(runtime.phase == MatchRuntime.Phase.OVERTIME, "time tie enters overtime")
	runtime.commit_tick(149, [], events)
	check(runtime.phase == MatchRuntime.Phase.OVERTIME, "overtime lasts full deadline")
	runtime.commit_tick(150, [], events)
	check(runtime.snapshot().winner == -1 and runtime.snapshot().reason == &"overtime_draw", "overtime timeout draws")
	runtime = _runtime()
	runtime.commit_tick(120, [], events)
	runtime.commit_tick(150, [_kill(1, 2, 0)], events)
	check(runtime.snapshot().winner == 1, "overtime final tick kill beats draw")

func _runtime(target: int = 2) -> MatchRuntime:
	var rules := MatchRules.new()
	rules.team_size = 1
	rules.duration_ticks = 120
	rules.overtime_ticks = 30
	rules.target_score = target
	var runtime := MatchRuntime.new()
	check(runtime.configure("test", rules, {1: 0, 2: 1}).is_empty(), "test runtime configured")
	return runtime

func _kill(target: int, source: int, life: int) -> Dictionary:
	return {"target_id": target, "source_id": source, "life_index": life,
		"actual_damage": 120, "died": true, "training": false}

func _events() -> BattleEvents:
	var events := BattleEvents.new()
	events.published.connect(func(event: Dictionary) -> void: seen.append(event))
	return events

func _count(kind: StringName) -> int:
	var count: int = 0
	for event: Dictionary in seen:
		if event.kind == kind:
			count += 1
	return count

func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
