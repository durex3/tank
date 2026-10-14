extends Node3D
class_name WorldHealthBar
## Lightweight billboard health indicator, driven by committed HP values.

const STYLE: Resource = preload("res://content/presentation/world_health.tres")

var friendly: bool = false
var _label := Label3D.new()
var _number := Label3D.new()
var _back := Sprite3D.new()
var _fill := Sprite3D.new()

func _ready() -> void:
	for sprite: Sprite3D in [_back, _fill]:
		var texture := GradientTexture2D.new()
		texture.width = 128
		texture.height = 16
		texture.gradient = Gradient.new()
		var color := Color("17222d") if sprite == _back else (Color("4fe69b") if friendly else Color("ff7374"))
		texture.gradient.colors = PackedColorArray([color, color])
		sprite.texture = texture
		sprite.pixel_size = 0.012
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = false
		sprite.no_depth_test = true
		sprite.render_priority = 1 if sprite == _fill else 0
		add_child(sprite)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","PingFang SC","Hiragino Sans GB","Noto Sans CJK SC"])
	font.font_weight = 700
	for label: Label3D in [_label,_number]:
		label.font = font
		label.font_size = 24 if label == _label else 20
		label.pixel_size = 0.010
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.outline_size = STYLE.outline_size
		label.render_priority = 3
		add_child(label)
	_label.position.y = STYLE.caption_gap
	_label.modulate = Color("a3edb0") if friendly else Color("ffa5a2")

func show_health(hp: int, maximum: int, caption: String = "") -> void:
	var ratio := clampf(float(hp) / maxi(maximum, 1), 0.0, 1.0)
	_fill.visible = ratio > 0.0
	_fill.scale.x = maxf(ratio, 0.001)
	_fill.offset.x = -64.0 * (1.0 - ratio) / maxf(ratio, 0.001)
	_label.text = caption
	_number.text = str(hp)
