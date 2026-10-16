extends Node3D
class_name BubbleVisual
## Image-based film with a clear center. Cosmetic movement never moves a hurtbox.

var film := Sprite3D.new()
var trail: Sprite3D
var volume := MeshInstance3D.new()
var field_ring: MeshInstance3D
var style: AbilityEffectStyle

func configure(radius: float, team: int, field: bool, tuning: AbilityEffectStyle) -> void:
	style = tuning
	_setup_sprite(film,style.bubble_film,radius*2/style.bubble_texture_fill)
	film.modulate = Color.WHITE if team == 0 else style.bubble_enemy_tint
	add_child(film)
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius*2
	sphere.radial_segments = 24
	sphere.rings = 12
	var membrane := ShaderMaterial.new()
	membrane.shader = preload("res://presentation/shaders/bubble_membrane.gdshader")
	membrane.set_shader_parameter("tint",style.bubble_color if team == 0 else style.bubble_enemy_color)
	volume.mesh = sphere
	volume.material_override = membrane
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(volume)
	if field:
		field_ring = MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = radius-style.bubble_outline_width_m
		ring.outer_radius = radius
		ring.rings = 32 if team == 0 else 4
		ring.ring_segments = 4
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(style.bubble_color if team == 0 else style.bubble_enemy_color,style.bubble_ground_opacity)
		ring.material = material
		field_ring.mesh = ring
		field_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		field_ring.position.y = style.ground_height-0.2
		add_child(field_ring)
	else:
		trail = Sprite3D.new()
		_setup_sprite(trail,style.bubble_film,radius*style.bubble_trail_ratio)
		trail.modulate = Color(1,1,1,0.55)
		add_child(trail)

func present(shot: ProjectileState, tick: int) -> void:
	position = shot.position
	var age: int = maxi(0,tick-shot.spawn_tick)
	var phase: float = age*style.bubble_bob_rate+shot.projectile_id*1.7
	if shot.kind == &"bubble_field":
		film.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		film.rotation.x = -PI/2
		film.position.y = -0.15
		film.scale = Vector3.ONE*(0.94+sin(phase)*0.025)
		volume.scale = Vector3(1,0.07,1)
		volume.position.y = -0.1
		return
	if shot.kind == &"bubble_barrier":
		var grow: float = lerpf(style.bubble_start_scale,1.0,minf(1.0,float(age)/style.bubble_expand_ticks))
		var fade: float = clampf(float(shot.spawn_tick+shot.lifetime_ticks-tick)/style.bubble_fade_ticks,0,1)
		film.scale = Vector3(grow*(1+sin(phase)*style.bubble_wobble),grow*(1-sin(phase)*style.bubble_wobble),1)*fade
		film.position.y = sin(phase)*style.bubble_bob_m
		film.modulate.a = fade
		field_ring.scale = Vector3.ONE*fade
		volume.scale = Vector3.ONE*grow*fade
		volume.position.y = film.position.y
	else:
		film.scale = Vector3(1+sin(phase)*style.bubble_wobble,1-sin(phase)*style.bubble_wobble,1)
		trail.position = -shot.direction*style.bubble_trail_distance_m

static func _setup_sprite(sprite: Sprite3D, texture: Texture2D, width: float) -> void:
	sprite.texture = texture
	sprite.pixel_size = width/texture.get_width()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
