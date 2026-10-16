extends Node3D
class_name TrainingTargetView
## Training mockup uses catalog parts; collision and lifecycle stay in TrainingTarget.

var target_id: int
var chassis_id: StringName = &"light_tracks"
var caption: String = "训练靶"
var _moving: bool = false
var _hp: int
var _maximum: int
var _bar := WorldHealthBar.new()
var _tank := TankView.new()

func _ready() -> void:
	_tank.entity_id = target_id
	_tank.chassis_id = chassis_id
	# Fit the existing 1.3m training footprint. This is a dummy, not a loadout actor.
	_tank.scale = Vector3.ONE * 0.65
	_tank.rotation.y = PI * 0.5
	add_child(_tank)
	_bar.position.y = WorldHealthBar.STYLE.target_height
	add_child(_bar)
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.70
	mesh.outer_radius = mesh.inner_radius + TankSurfacePolish.STYLE.team_ring_width
	mesh.rings = 32
	mesh.ring_segments = 6
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("d95c63")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = TankSurfacePolish.STYLE.team_ring_opacity
	mesh.material = material
	ring.mesh = mesh
	ring.position.y = 0.055
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

func show_health(hp: int, maximum: int) -> void:
	_hp = hp
	_maximum = maximum
	_bar.show_health(hp,maximum,caption+(" · 移动" if _moving else ""))
	_tank.visible = hp > 0

func on_event(event: Dictionary) -> void:
	_tank.on_event(event)
	if event.get("target_id",-1) != target_id: return
	if event.kind == &"damage_applied" or event.kind == &"entity_respawned":
		show_health(event.hp,event.max_hp)

func set_moving(value: bool) -> void:
	_moving = value
	show_health(_hp,_maximum)
