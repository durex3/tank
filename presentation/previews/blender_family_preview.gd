extends HangarPreview
## Isolated art inspection; no gameplay or catalog mutation.

var candidate := Node3D.new()
var _dragging: bool = false

func _ready() -> void:
	super._ready()
	tank.hide()
	add_child(candidate)
	candidate.rotation.y = tank.rotation.y
	var hull := preload("res://assets/derived/blender-family-v1/scout_wheels.glb").instantiate() as Node3D
	var turret := preload("res://assets/derived/blender-family-v1/cannon.glb").instantiate() as Node3D
	candidate.add_child(hull)
	candidate.add_child(turret)
	turret.position.y = 0.88
	var camera := get_viewport().get_camera_3d()
	camera.size = 3.5
	camera.look_at(Vector3(0, 0.9, 0))
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var label := Label.new()
	label.position = Vector2(24, 20)
	label.text = "Blender 主战炮 + 四轮底盘 · 独立样板\n拖动旋转 | Esc 退出"
	label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(label)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		candidate.rotation.y += event.relative.x * 0.008
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_dragging = false
