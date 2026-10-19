extends Node3D
class_name TankHealthView
## Entity-scoped health presentation, never mutates combat state.

var entity_id: int
var friendly: bool = true
var visual: TankView
var _hp: int
var _maximum: int
var _protected: bool = false
var _bar := WorldHealthBar.new()

func _ready() -> void:
	_bar.position.y = WorldHealthBar.STYLE.actor_height
	_bar.friendly = friendly
	add_child(_bar)
	_add_team_ring()

func show_health(hp: int, maximum: int, protected: bool = false) -> void:
	_hp = hp
	_maximum = maximum
	_protected = protected
	var caption := "你的战车" if friendly else "对练坦克"
	if _protected:
		caption += " · 保护"
	if hp <= 0:
		caption += " · 重建"
	_bar.show_health(hp, maximum, caption)
	if visual != null:
		visual.visible = hp > 0

func on_event(event: Dictionary) -> void:
	if event.get("target_id", -1) != entity_id:
		return
	if event.kind == &"damage_applied" or event.kind == &"entity_respawned":
		show_health(event.hp, event.max_hp, event.get("protected", false))
	elif event.kind == &"protection_changed":
		show_health(_hp, _maximum, event.protected)

func _add_team_ring() -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.72
	mesh.outer_radius = mesh.inner_radius + TankSurfacePolish.STYLE.team_ring_width
	mesh.rings = 20
	mesh.ring_segments = 6
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("21c5da") if friendly else Color("e35f66")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = TankSurfacePolish.STYLE.team_ring_opacity
	mesh.material = material
	ring.mesh = mesh
	ring.position.y = 0.06
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
