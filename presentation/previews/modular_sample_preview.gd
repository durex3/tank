extends HangarPreview
## Standalone art review using the real hangar environment; never creates a battle.

var candidate := Node3D.new()
var _dragging: bool = false
var _show_old: bool = false
var _label: Label

func _ready() -> void:
	super._ready()
	assert(tank.configure_parts(&"autocannon", &"scout_wheels").is_empty())
	tank.hide()
	add_child(candidate)
	candidate.rotation.y = tank.rotation.y
	var hull := preload("res://presentation/parts/modular_sample_v1/c03.tscn").instantiate() as Node3D
	var turret := preload("res://presentation/parts/modular_sample_v1/t02.tscn").instantiate() as Node3D
	assert(TankPartCatalog.validate_part(hull, &"TurretSocket", Vector3(0, 0.76, 0)).is_empty())
	assert(TankPartCatalog.validate_part(turret, &"Muzzle", Vector3(0, 0.02, -1.05)).is_empty())
	candidate.add_child(hull)
	candidate.add_child(turret)
	turret.position = (hull.get_node("TurretSocket") as Marker3D).position
	var camera := get_viewport().get_camera_3d()
	camera.size = 3.5
	camera.look_at(Vector3(0, 0.9, 0))
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(_label)
	_update_label()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		set_review_yaw(candidate.rotation.y + event.relative.x * 0.008)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_show_old = not _show_old
			tank.visible = _show_old
			candidate.visible = not _show_old
			_update_label()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_dragging = false

func set_review_yaw(angle: float) -> void:
	candidate.rotation.y = angle
	tank.rotation.y = angle

func _update_label() -> void:
	_label.text = ("原模型对照" if _show_old else "比例修正版 · 炮塔等比缩小22%") + "\n拖动旋转  |  空格切换新旧  |  Esc退出"
