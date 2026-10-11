extends Node3D
class_name WorldHealthBar
## Lightweight billboard health indicator, driven by committed HP values.

var friendly: bool = false
var _label := Label3D.new()
var _back := Sprite3D.new()
var _fill := Sprite3D.new()

func _ready() -> void:
	for sprite: Sprite3D in [_back, _fill]:
		var texture := GradientTexture2D.new()
		texture.width = 128
		texture.height = 10
		texture.gradient = Gradient.new()
		var color := Color("17222d") if sprite == _back else (Color("4fe69b") if friendly else Color("ff7374"))
		texture.gradient.colors = PackedColorArray([color, color])
		sprite.texture = texture
		sprite.pixel_size = 0.014
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = false
		sprite.no_depth_test = true
		sprite.render_priority = 1 if sprite == _fill else 0
		add_child(sprite)
	_label.position.y = 0.28
	_label.font_size = 28
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.outline_size = 8
	add_child(_label)

func show_health(hp: int, maximum: int, caption: String = "") -> void:
	var ratio := clampf(float(hp) / maxi(maximum, 1), 0.0, 1.0)
	_fill.visible = ratio > 0.0
	_fill.scale.x = maxf(ratio, 0.001)
	_fill.offset.x = -64.0 * (1.0 - ratio) / maxf(ratio, 0.001)
	_label.text = "%s %d / %d" % [caption, hp, maximum]
