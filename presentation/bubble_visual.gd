extends Node3D
class_name BubbleVisual
## Water silhouette and flat field, aged only from committed projectile snapshots.

var film: Sprite3D
var trail: Sprite3D
var style: AbilityEffectStyle
var _field: bool = false

func configure(radius: float, team: int, field: bool, tuning: AbilityEffectStyle) -> void:
	style = tuning
	_field = field
	film = ToonFxMaterials.create(&"drop",&"water",2 if field else 1,radius*2/style.bubble_texture_fill,not field)
	film.modulate = Color.WHITE if team == 0 else style.bubble_enemy_tint
	add_child(film)
	if field:
		film.rotation.x = -PI/2
		film.position.y = style.ground_height-0.2
	else:
		trail = ToonFxMaterials.create(&"drop",&"water",3,radius*style.bubble_trail_ratio)
		trail.modulate = Color(1,1,1,0.55)
		add_child(trail)

func present(shot: ProjectileState, tick: int) -> void:
	position = shot.position
	var age: int = maxi(0,tick-shot.spawn_tick)
	var life: float = clampf(float(age)/maxi(1,shot.lifetime_ticks),0,1)
	ToonFxMaterials.advance(film,life)
	var phase: float = age*style.bubble_bob_rate+shot.projectile_id*1.7
	if _field:
		film.scale = Vector3.ONE*(0.94+sin(phase)*0.025)
	else:
		film.scale = Vector3(1+sin(phase)*style.bubble_wobble,1-sin(phase)*style.bubble_wobble,1)
		trail.position = -shot.direction*style.bubble_trail_distance_m
		ToonFxMaterials.advance(trail,life)

static func _setup_sprite(sprite: Sprite3D, texture: Texture2D, width: float) -> void:
	sprite.texture = texture
	sprite.pixel_size = width/texture.get_width()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
