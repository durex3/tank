extends Node3D
class_name TrainingTargetView

var _moving: bool = false
var _hp: int
var _maximum: int
var target_id: int
var _bar := WorldHealthBar.new()
var _body := MeshInstance3D.new()
var _material := StandardMaterial3D.new()

func _ready() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.65
	cylinder.bottom_radius = 0.65
	cylinder.height = 1.4
	_material.albedo_color = Color("e1dfcf")
	cylinder.material = _material
	_body.mesh = cylinder
	_body.position.y = 0.7
	add_child(_body)
	_bar.position.y = 1.75
	add_child(_bar)
	var marker := MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 0.38
	ring.bottom_radius = 0.38
	ring.height = 0.04
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color("e36b54")
	ring.material = accent
	marker.mesh = ring
	marker.position = Vector3(0, 0.8, 0.63)
	marker.rotation.x = PI * 0.5
	add_child(marker)

func show_health(hp: int, maximum: int) -> void:
	_hp = hp
	_maximum = maximum
	_bar.show_health(hp, maximum, "MOVING" if _moving else "TARGET")
	_material.albedo_color = Color("e1dfcf") if hp > 0 else Color("444c51")

func on_event(event: Dictionary) -> void:
	if event.target_id != target_id:
		return
	if event.kind == &"damage_applied" or event.kind == &"entity_respawned":
		show_health(event.hp, event.max_hp)

func set_moving(value: bool) -> void:
	_moving = value
	show_health(_hp, _maximum)
