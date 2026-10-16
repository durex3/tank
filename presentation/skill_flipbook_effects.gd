extends Node3D
class_name SkillFlipbookEffects
## Generated transparent frames; committed ticks own playback and pause behavior.

var style: SkillFlipbookStyle = preload("res://content/presentation/skill_flipbooks.tres")
var _clips: Array[Dictionary] = []
var _textures: Dictionary = {}
var _seen: Dictionary = {}
var _storm_until: Dictionary = {}

func on_event(event: Dictionary) -> void:
	var tick: int = event.tick
	for key: String in _seen.keys():
		if tick > int(_seen[key]): _seen.erase(key)
	var keep: Array[Dictionary] = []
	for clip: Dictionary in _clips:
		var frame: int = (tick-int(clip.start))/style.frame_ticks
		if frame >= 4 or (event.kind == &"ability_state" and not event.alive and event.source_id == clip.owner):
			(clip.node as Node).queue_free()
		else:
			(clip.node as Sprite3D).texture = _texture(clip.art,maxi(0,frame))
			keep.append(clip)
	_clips = keep
	if event.kind == &"match_finished":
		clear()
		return
	if event.kind == &"projectile_hit" and event.get("weapon",&"") == &"cannon" and not event.get("ability_damage",false):
		var id: int = int(event.get("projectile_id",0))
		_spawn("armor",event.position,tick,id,style.armor_width)
		_spawn("dust",event.position,tick,id,style.dust_width*0.6)
	if event.kind == &"damage_applied" and event.get("ability_id",&"") == &"breach" and event.get("actual_damage",0) > 0:
		var center: Vector3 = event.position
		var camera := get_viewport().get_camera_3d()
		if camera != null: center += camera.global_basis.z*style.hit_camera_offset
		_spawn("lightning",center,tick,event.target_id,style.energy_hit_width,int(event.get("projectile_id",0)),style.energy_hit_tint)
	if event.kind == &"damage_applied" and event.get("ability_id",&"") == &"storm" and event.get("actual_damage",0) > 0:
		var target: int = event.target_id
		if tick >= int(_storm_until.get(target,-1)):
			_storm_until[target] = tick+style.storm_hit_interval
			var center: Vector3 = event.position
			var camera := get_viewport().get_camera_3d()
			if camera != null: center += camera.global_basis.z*style.hit_camera_offset
			_spawn("armor",center,tick,target,style.storm_hit_width,int(event.get("projectile_id",0)),Color(1,0.65,0.35,0.9))
	if event.kind == &"damage_applied" and event.get("guarded",false):
		_spawn("armor",event.position,tick,event.target_id,style.armor_width)
	elif event.kind == &"ability_state" and event.alive:
		if event.phase == &"dash" and tick % style.trail_interval == 0:
			_spawn("dust",event.position+Vector3.UP*0.3,tick,event.source_id,style.dust_width)
		elif event.get("cruise",false) and tick % style.reload_interval == 0:
			var lateral := Vector3(cos(event.body_yaw),0,sin(event.body_yaw))
			for side: int in [-1,1]:
				_spawn("reload",event.position+Vector3.UP*0.35+lateral*side*0.85,tick,event.source_id,style.reload_width,side)

func _texture(art: String, frame: int) -> Texture2D:
	var key: String = "%s-%d" % [art,frame]
	if not _textures.has(key): _textures[key] = load("res://assets/generated/vfx/skills-v2/%s.png" % key)
	return _textures[key]

func _spawn(art: String, center: Vector3, tick: int, owner: int, width: float, slot: int = 0, tint: Color = Color.WHITE) -> void:
	var key: String = "%s:%d:%d:%d" % [art,tick,owner,slot]
	if _seen.has(key) or _clips.size() >= style.max_clips: return
	_seen[key] = tick+style.frame_ticks*4
	var sprite := Sprite3D.new()
	sprite.texture = _texture(art,0)
	sprite.modulate = tint
	sprite.pixel_size = width/256.0
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.position = center
	add_child(sprite)
	_clips.append({"node":sprite,"art":art,"start":tick,"owner":owner})

func clear() -> void:
	for clip: Dictionary in _clips: (clip.node as Node).queue_free()
	_clips.clear()
	_seen.clear()
	_storm_until.clear()
