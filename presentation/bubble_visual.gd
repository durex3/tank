extends Node3D
class_name BubbleVisual
## Water silhouette and flat field, aged only from committed projectile snapshots.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

var film: Sprite3D
var trail: Sprite3D
var style: AbilityEffectStyle
var _field: bool = false
var _ultimate_scale: float = 1.0

func configure(radius: float, team: int, field: bool, tuning: AbilityEffectStyle, ultimate: bool = false) -> void:
	style = tuning
	_field = field
	_ultimate_scale = style.bubble_ultimate_scale if ultimate else 1.0
	film = TOON_FX.create(&"drop",&"water",2,radius*2,false) if field else TOON_FX.water(radius*2/style.bubble_texture_fill)
	film.modulate = Color.WHITE if team == 0 else style.bubble_enemy_tint
	add_child(film)
	if field:
		(film.material_override as ShaderMaterial).set_shader_parameter("ground_pool",true)
		(film.material_override as ShaderMaterial).set_shader_parameter("pool_fill",style.bubble_field_fill)
		(film.material_override as ShaderMaterial).set_shader_parameter("pool_edge",style.bubble_field_edge)
		(film.material_override as ShaderMaterial).set_shader_parameter("uv_zoom",1.0)
		film.rotation.x = -PI/2
		film.position.y = style.ground_height-0.2
	else:
		trail = TOON_FX.water(radius*style.bubble_trail_ratio)
		trail.modulate = Color(1,1,1,0.55)
		add_child(trail)

func present(shot: ProjectileState, tick: int) -> void:
	position = shot.position
	var age: int = maxi(0,tick-shot.spawn_tick)
	var life: float = clampf(float(age)/maxi(1,shot.lifetime_ticks),0,1)
	# Lobs have arc_ticks, not a field lifetime until landing; never fade them as expired fields.
	if shot.kind == &"bubble_lob": life = minf(0.65,float(age)/maxi(1,shot.arc_ticks)*0.65)
	TOON_FX.advance(film,life)
	var phase: float = age*style.bubble_bob_rate+shot.projectile_id*1.7
	if _field:
		film.scale = Vector3.ONE
		film.modulate.a = clampf(float(shot.lifetime_ticks-age)/style.bubble_fade_ticks,0,1)
	else:
		film.scale = Vector3(1+sin(phase)*style.bubble_wobble,1-sin(phase)*style.bubble_wobble,1)*_ultimate_scale
		var direction: Vector3 = (shot.position-shot.previous_position).normalized() if shot.kind == &"bubble_lob" else shot.direction
		trail.position = -direction*style.bubble_trail_distance_m
		TOON_FX.advance(trail,life)

static func _setup_sprite(sprite: Sprite3D, texture: Texture2D, width: float) -> void:
	sprite.texture = texture
	sprite.pixel_size = width/texture.get_width()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
