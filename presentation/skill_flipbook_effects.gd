extends Node3D
class_name SkillFlipbookEffects
## Generated transparent frames; committed ticks own playback and pause behavior.

const TOON_FX = preload("res://presentation/toon_fx_materials.gd")

var style: SkillFlipbookStyle = preload("res://content/presentation/skill_flipbooks.tres")
var _clips: Array[Dictionary] = []
var _seen: Dictionary = {}
var _storm_until: Dictionary = {}
var _shot_directions: Dictionary = {}
const PARTICLE_GROUP = preload("res://presentation/toon_particle_group.gd")

func on_event(event: Dictionary) -> void:
	var tick: int = event.tick
	if event.kind == &"ability_fired" and event.ability == &"breach":
		_shot_directions[int(event.get("projectile_id",-1))] = {"direction":Vector3(sin(event.yaw),0,-cos(event.yaw)),"until":tick+style.debris_ticks}
	for id: int in _shot_directions.keys():
		if tick > int(_shot_directions[id].until): _shot_directions.erase(id)
	for key: String in _seen.keys():
		if tick > int(_seen[key]): _seen.erase(key)
	var keep: Array[Dictionary] = []
	for clip: Dictionary in _clips:
		var duration: int = int(clip.get("duration",style.frame_ticks*4))
		var age: int = tick-int(clip.start)
		if age >= duration or (event.kind in [&"entity_died",&"entity_respawned"] and event.get("target_id",-1) == clip.owner) or (event.kind == &"ability_state" and not event.alive and event.source_id == clip.owner):
			(clip.node as Node).queue_free()
		else:
			if clip.art == "breach_debris": clip.node.step(age)
			else:
				TOON_FX.advance(clip.node as Sprite3D,float(age)/duration)
				var progress: float = float(age)/duration
				(clip.node as Node3D).scale = Vector3.ONE*(lerpf(0.65,1.0,progress/0.18) if progress < 0.18 else lerpf(1.0,0.5,(progress-0.18)/0.82))
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
	if art == "breach_debris":
		var group := PARTICLE_GROUP.new()
		var direction: Vector3 = _shot_directions.get(slot,{}).get("direction",Vector3.FORWARD)
		group.configure(center,direction,style,absi(slot))
		add_child(group)
		_clips.append({"node":group,"art":art,"start":tick,"owner":owner,"duration":style.debris_ticks})
		return
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
	var sprite: Sprite3D = TOON_FX.contact(width,family) if art in ["armor","lightning","guard"] else TOON_FX.create(sheet,family,cell,width)
	sprite.modulate = tint if art == "lightning" else Color(1,1,1,tint.a)
	sprite.position = center
	add_child(sprite)
	_clips.append({"node":sprite,"art":art,"start":tick,"owner":owner,"duration":style.contact_ticks if art in ["armor","lightning","guard"] else style.frame_ticks*4})

func clear() -> void:
	for clip: Dictionary in _clips: (clip.node as Node).queue_free()
	_clips.clear()
	_seen.clear()
	_storm_until.clear()
	_shot_directions.clear()
