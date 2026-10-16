extends HangarPreview
## Standalone mechanical inspection, independent of battle state and input.

var candidate := Node3D.new()
var _dragging: bool = false
var _animate: bool = false
var _phase: float = 0.0
var _wheels: Array[Node] = []
var _left: Node3D
var _right: Node3D

func _ready() -> void:
	super._ready()
	tank.hide()
	add_child(candidate)
	candidate.rotation.y = tank.rotation.y
	var hull := preload("res://assets/derived/hyper3d-refined-v1/c03.glb").instantiate() as Node3D
	var turret := preload("res://assets/derived/hyper3d-refined-v1/t02.glb").instantiate() as Node3D
	candidate.add_child(hull)
	candidate.add_child(turret)
	turret.position.y = 0.88
	_wheels = candidate.find_children("Wheel*", "Node3D", true, false)
	_left = candidate.find_children("RecoilLeft*", "Node3D", true, false)[0] as Node3D
	_right = candidate.find_children("RecoilRight*", "Node3D", true, false)[0] as Node3D
	var camera := get_viewport().get_camera_3d()
	camera.size = 3.5
	camera.look_at(Vector3(0, 0.9, 0))
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var label := Label.new()
	label.position = Vector2(24, 20)
	label.text = "Hyper3D + Blender 修整样板\n拖动旋转 | 空格：机械动作检查 | Esc 退出"
	label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(label)

func _process(delta: float) -> void:
	if _animate:
		_phase += delta
		set_review_pose(_phase)

func set_review_pose(phase: float) -> void:
	for wheel: Node3D in _wheels:
		wheel.rotation.x = phase * 2.0
	_left.position.z = maxf(0.0, sin(phase * TAU)) * 0.04
	_right.position.z = maxf(0.0, -sin(phase * TAU)) * 0.04

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		candidate.rotation.y += event.relative.x * 0.008
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_SPACE:
			_animate = not _animate
			if not _animate:
				_phase = 0.0
				set_review_pose(0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_dragging = false
		_animate = false
