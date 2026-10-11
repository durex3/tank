extends Node
## Composition root owns screen lifecycle and input teardown.

const HANGAR := preload("res://ui/screens/hangar_screen.tscn")
const HOME := preload("res://ui/screens/project_home.tscn")
const MOVEMENT := preload("res://ui/screens/movement_screen.tscn")
const INPUT_LAB := preload("res://ui/screens/input_lab.tscn")

var _returning_from_trial: bool = false
var _hangar_weapon: StringName = &"cannon"
var _hangar_chassis: StringName = &"light_tracks"

func _ready() -> void:
	_show_home()

func _show_home() -> void:
	_returning_from_trial = false
	_clear_screen()
	var screen := HOME.instantiate()
	screen.input_lab_requested.connect(_show_input_lab)
	screen.hangar_requested.connect(_show_hangar)
	screen.movement_requested.connect(_show_movement)
	$ScreenHost.add_child(screen)

func _show_input_lab() -> void:
	_clear_screen()
	var screen := INPUT_LAB.instantiate()
	screen.back_requested.connect(_show_home)
	$ScreenHost.add_child(screen)

func _clear_screen() -> void:
	for screen: Node in $ScreenHost.get_children():
		if "session" in screen and screen.session is MovementSession:
			screen.session.stop()
		$ScreenHost.remove_child(screen)
		screen.queue_free()

func _show_movement() -> void:
	_clear_screen()
	var screen := MOVEMENT.instantiate()
	screen.back_requested.connect(_show_home)
	screen.duel_requested.connect(_open_duel.bind(false))
	$ScreenHost.add_child(screen)

func _show_hangar() -> void:
	_clear_screen()
	var screen := HANGAR.instantiate()
	screen.back_requested.connect(_show_home)
	screen.training_requested.connect(_train_loadout)
	$ScreenHost.add_child(screen)
	if _returning_from_trial:
		screen.restore_selection(_hangar_weapon, _hangar_chassis)
	_returning_from_trial = false

func _train_loadout(weapon_id: StringName, chassis_id: StringName) -> void:
	var screen := MOVEMENT.instantiate()
	var error: String = _configure_training(screen, weapon_id, chassis_id)
	if not error.is_empty():
		screen.free()
		push_error(error)
		return
	_returning_from_trial = true
	_hangar_weapon = weapon_id
	_hangar_chassis = chassis_id
	_clear_screen()
	screen.back_requested.connect(_show_hangar)
	screen.duel_requested.connect(_open_duel.bind(true))
	$ScreenHost.add_child(screen)

func _open_duel(weapon_id: StringName, chassis_id: StringName, touch_mode: bool, from_hangar: bool) -> void:
	_returning_from_trial = from_hangar
	var screen := MOVEMENT.instantiate()
	var error: String = screen.session.configure_loadout(weapon_id, chassis_id)
	if error.is_empty():
		error = screen.session.configure_match(preload("res://content/rules/offline_duel.tres"))
	if not error.is_empty():
		screen.free()
		push_error(error)
		return
	_clear_screen()
	screen.back_requested.connect(_show_hangar if from_hangar else _show_home)
	screen.duel_requested.connect(_open_duel.bind(from_hangar))
	$ScreenHost.add_child(screen)
	screen.session.set_touch_mode(touch_mode)

func _configure_training(screen: Node, weapon_id: StringName, chassis_id: StringName) -> String:
	var equipment := EquipmentService.new()
	var error := equipment.open()
	if not error.is_empty():
		return error
	return screen.session.configure_loadout(weapon_id, chassis_id, equipment.profile.level_of(weapon_id), equipment.profile.level_of(chassis_id))
