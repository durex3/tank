extends Node3D
class_name SkillFlipbookEffects
## Generated transparent frames; committed ticks own playback and pause behavior.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

var style: SkillFlipbookStyle = preload("res://content/presentation/skill_flipbooks.tres")
var _clips: Array[Dictionary] = []
var _seen: Dictionary = {}
var _storm_until: Dictionary = {}

func on_event(event: Dictionary) -> void:
	var tick: int = event.tick
	for key: String in _seen.keys():
		if tick > int(_seen[key]): _seen.erase(key)
	var keep: Array[Dictionary] = []
	for clip: Dictionary in _clips:
		var frame: int = (tick-int(clip.start))/style.frame_ticks
		if frame >= 4 or (event.kind in [&"entity_died",&"entity_respawned"] and event.get("target_id",-1) == clip.owner) or (event.kind == &"ability_state" and not event.alive and event.source_id == clip.owner):
			(clip.node as Node).queue_free()
		else:
			TOON_FX.advance(clip.node as Sprite3D, float(tick-int(clip.start))/(style.frame_ticks*4))
			keep.append(clip)
	_clips = keep
	if event.kind == &"match_finished":
		clear()
		return
	if event.kind == &"projectile_hit" and event.get("weapon",&"") == &"cannon" and not event.get("ability_damage",false):
		var id: int = int(event.get("target_id",event.get("source_id",-1)))
		var slot: int = int(event.get("projectile_id",0))
		_spawn("armor",event.position,tick,id,style.armor_width,slot)
		_spawn("dust",event.position,tick,id,style.dust_width*0.6,slot)
	if event.kind == &"damage_applied" and event.get("ability_id",&"") == &"breach" and event.get("actual_damage",0) > 0:
		var center: Vector3 = event.position
		var camera := get_viewport().get_camera_3d()
		if camera != null: center += camera.global_basis.z*style.hit_camera_offset
		_spawn("lightning",center,tick,event.target_id,style.energy_hit_width,int(event.get("projectile_id",0)),style.energy_hit_tint)
		_spawn("breach_debris",center,tick,event.target_id,style.energy_hit_width*0.8,int(event.get("projectile_id",0)))
	if event.kind == &"damage_applied" and event.get("ability_id",&"") == &"storm" and event.get("actual_damage",0) > 0:
		var target: int = event.target_id
		if tick >= int(_storm_until.get(target,-1)):
			_storm_until[target] = tick+style.storm_hit_interval
			var center: Vector3 = event.position
			var camera := get_viewport().get_camera_3d()
			if camera != null: center += camera.global_basis.z*style.hit_camera_offset
			_spawn("armor",center,tick,target,style.storm_hit_width,int(event.get("projectile_id",0)),Color(1,0.65,0.35,0.9))
	if event.kind == &"damage_applied" and event.get("guarded",false):
		_spawn("guard",event.position,tick,event.target_id,style.armor_width)
	elif event.kind == &"ability_state" and event.alive:
		if event.phase == &"dash" and tick % style.trail_interval == 0:
			_spawn("dust",event.position+Vector3.UP*0.3,tick,event.source_id,style.dust_width)
		elif event.get("cruise",false) and tick % style.reload_interval == 0:
			var lateral := Vector3(cos(event.body_yaw),0,sin(event.body_yaw))
			for side: int in [-1,1]:
				_spawn("reload",event.position+Vector3.UP*0.35+lateral*side*0.85,tick,event.source_id,style.reload_width,side)

func _spawn(art: String, center: Vector3, tick: int, owner: int, width: float, slot: int = 0, tint: Color = Color.WHITE) -> void:
	var key: String = "%s:%d:%d:%d" % [art,tick,owner,slot]
	if _seen.has(key) or _clips.size() >= style.max_clips: return
	_seen[key] = tick+style.frame_ticks*4
	var sheet: StringName = &"flash"
	var family: StringName = &"metal"
	var cell: int = 1
	match art:
		"breach_debris":
			sheet = &"debris"
			family = &"metal"
			cell = 3
		"guard":
			sheet = &"zap"
			family = &"guard"
			cell = 3
		"dust":
			sheet = &"smoke"
			family = &"dust"
			cell = 0
		"reload":
			sheet = &"streak"
			family = &"warm"
			cell = 1
		"lightning":
			sheet = &"flash"
			family = &"warm"
			cell = 1
	var sprite: Sprite3D = TOON_FX.create(sheet,family,cell,width)
	sprite.modulate = tint if art == "lightning" else Color(1,1,1,tint.a)
	sprite.position = center
	add_child(sprite)
	_clips.append({"node":sprite,"art":art,"start":tick,"owner":owner})

func clear() -> void:
	for clip: Dictionary in _clips: (clip.node as Node).queue_free()
	_clips.clear()
	_seen.clear()
	_storm_until.clear()
