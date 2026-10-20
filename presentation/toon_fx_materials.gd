extends RefCounted
class_name ToonFxMaterials
## Adapter for the toon sheet shader. Life is injected from committed ticks only.

const MATERIALS: Dictionary = {
	&"warm": preload("res://content/presentation/toon_fx_warm.tres"),
	&"metal": preload("res://content/presentation/toon_fx_metal.tres"),
	&"water": preload("res://content/presentation/toon_fx_water.tres"),
	&"dust": preload("res://content/presentation/toon_fx_dust.tres"),
	&"guard": preload("res://content/presentation/toon_fx_guard.tres"),
}

const SHEETS: Dictionary = {
	&"flash": preload("res://assets/generated/vfx/toon-fx-v1/toon_flash_2x2.png"),
	&"smoke": preload("res://assets/generated/vfx/toon-fx-v1/toon_smoke_2x2.png"),
	&"drop": preload("res://assets/generated/vfx/toon-fx-v1/toon_drop_2x2.png"),
	&"zap": preload("res://assets/generated/vfx/toon-fx-v1/toon_zap_2x2.png"),
	&"fire": preload("res://assets/generated/vfx/toon-fx-v1/toon_fire_2x2.png"),
	&"bolt": preload("res://assets/generated/vfx/toon-fx-v1/toon_bolt_2x2.png"),
	&"debris": preload("res://assets/generated/vfx/toon-fx-v1/toon_debris_2x2.png"),
	&"streak": preload("res://assets/generated/vfx/toon-fx-v1/toon_streak_2x2.png"),
}

static func create(art: StringName, family: StringName, cell: int, width: float, billboard: bool = true) -> Sprite3D:
	var sprite := Sprite3D.new()
	var sheet: Texture2D = SHEETS[art]
	# Sprite geometry uses one cell; shader handles atlas selection exactly once.
	sprite.texture = sheet
	sprite.pixel_size = width / float(sheet.get_width())
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	apply(sprite, sheet, family, cell, billboard)
	return sprite

static func apply(node: Sprite3D, sheet: Texture2D, family: StringName = &"warm",
		cell: int = 0, billboard: bool = true) -> void:
	var base: ShaderMaterial = MATERIALS.get(family, MATERIALS[&"warm"])
	var material: ShaderMaterial = base.duplicate()
	material.set_shader_parameter("life", 0.0)
	material.set_shader_parameter("sheet", sheet)
	material.set_shader_parameter("cell", float(cell))
	material.set_shader_parameter("billboard", billboard)
	node.material_override = material
	node.set_meta("toon_cell", cell)

static func advance(node: Sprite3D, life: float) -> void:
	if node.material_override is ShaderMaterial:
		(node.material_override as ShaderMaterial).set_shader_parameter("life", clampf(life, 0.0, 1.0))

static func contact(width: float, family: StringName = &"warm") -> Sprite3D:
	var sprite: Sprite3D = create(&"flash",family,0,width)
	var material := ShaderMaterial.new()
	material.shader = preload("res://presentation/shaders/toon_contact.gdshader")
	var palette: ShaderMaterial = MATERIALS[family]
	material.set_shader_parameter("ramp",palette.get_shader_parameter("ramp"))
	material.set_shader_parameter("life",0.0)
	sprite.material_override = material
	return sprite
