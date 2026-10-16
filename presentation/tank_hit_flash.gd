extends RefCounted
class_name TankHitFlash
## Per-view overlay; never modifies source materials or gameplay state.
var _surfaces: Array[Dictionary] = []
var _material: StandardMaterial3D
var _until: int = -1
var _last: int = -1
var _color: Color
var _duration: int
var style: SkillFlipbookStyle = preload("res://content/presentation/skill_flipbooks.tres")

func hit(view: Node3D, tick: int, storm: bool = false) -> void:
	if tick <= _last or (storm and tick < _last+style.storm_hit_interval): return
	clear()
	_last = tick
	_duration = style.storm_flash_ticks if storm else style.hit_flash_ticks
	_color = style.storm_flash_color if storm else style.hit_flash_color
	_until = tick+_duration
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = _color
	for mount: Node in [view._hull,view._turret]:
		for node: Node in mount.find_children("*","MeshInstance3D",true,false):
			var mesh := node as MeshInstance3D
			_surfaces.append({"mesh":mesh,"previous":mesh.material_overlay})
			mesh.material_overlay = _material

func advance(tick: int) -> void:
	if _until < 0: return
	if tick >= _until:
		clear()
	elif _material != null:
		var color: Color = _color
		color.a *= float(_until-tick)/_duration
		_material.albedo_color = color

func clear() -> void:
	for entry: Dictionary in _surfaces:
		if is_instance_valid(entry.mesh): entry.mesh.material_overlay = entry.previous
	_surfaces.clear()
	_material = null
	_until = -1
