extends Node3D
class_name AbilityEffects
## Session facts own lifetime. Ground cues are flat stencils; sprites own volume.

const GROUND_GEOMETRY = preload("res://presentation/toon_ground_geometry.gd")

var style: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var rules: BasicAbilityRules = preload("res://content/rules/basic_abilities.tres")
var _nodes: Dictionary = {}
var _zones := MeshInstance3D.new()
var _material: StandardMaterial3D = GROUND_GEOMETRY.material()
var _art := AbilitySpriteEffects.new()
var _signatures := AbilitySignatureEffects.new()
var _frames := SkillFlipbookEffects.new()
var _guard_hits: Dictionary = {}

func _ready() -> void:
	_zones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for node: Node in [_zones,_art,_signatures,_frames]: add_child(node)

func on_event(event: Dictionary) -> void:
	_art.on_event(event)
	_signatures.on_event(event)
	_frames.on_event(event)
	match event.kind:
		&"ability_state":
			if event.alive: _draw_actor(event)
			else: _remove(int(event.source_id))
		&"entity_died", &"entity_respawned": _remove(int(event.get("target_id",-1)))
		&"damage_applied":
			if event.get("guarded",false): _guard_hits[event.target_id] = event.tick+style.guard_hit_ticks
		&"ability_zones": _draw_zones(event.zones)
		&"match_finished": clear()

func _mesh() -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_material)
	GROUND_GEOMETRY.triangle(mesh,Vector3.ZERO,Vector3.RIGHT*0.001,Vector3.BACK*0.001,Color(0,0,0,0))
	return mesh

func _draw_actor(state: Dictionary) -> void:
	if not _nodes.has(state.source_id):
		var node := MeshInstance3D.new()
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		_nodes[state.source_id] = node
	var mesh: ImmediateMesh = _mesh()
	var origin: Vector3 = state.position+Vector3.UP*style.ground_height
	var front := Vector3(sin(state.body_yaw),0,-cos(state.body_yaw))
	var right := Vector3(-front.z,0,front.x)
	if state.guard:
		var color: Color = Color("eef6ff") if state.tick < int(_guard_hits.get(state.source_id,0)) else style.guard_color
		GROUND_GEOMETRY.arc(mesh,origin,style.guard_radius_m,state.body_yaw,deg_to_rad(rules.guard_half_angle),style.storm_ring_width_m,color,7)
	if state.get("escape_active",false) or state.get("cruise",false):
		var color: Color = style.escape_color if state.get("escape_active",false) else style.cruise_color
		for side: int in [-1,1]:
			for i: int in range(2):
				var p: Vector3 = origin+right*side*style.escape_arrow_span_m-front*(i+float(state.tick%18)/18.0)*style.escape_arrow_spacing_m
				GROUND_GEOMETRY.chevron(mesh,p,front,style.escape_arrow_spacing_m*0.55,color)
	if state.phase == &"breach":
		var aim := Vector3(sin(state.yaw),0,-cos(state.yaw))
		for i: int in range(2,int(rules.breach_range),2):
			GROUND_GEOMETRY.chevron(mesh,origin+aim*i,aim,style.line_width*3,Color(style.breach_color,0.7))
	elif state.phase in [&"shock",&"dash"]:
		var aim := Vector3(sin(state.locked_yaw),0,-cos(state.locked_yaw))
		for i: int in range(1,int(rules.dash_distance)):
			GROUND_GEOMETRY.chevron(mesh,origin+aim*i,aim,style.escape_arrow_spacing_m,style.shock_color)
	elif state.phase in [&"storm",&"cooling"]:
		var color: Color = style.storm_color if state.phase == &"storm" else style.cooling_color
		var duration: int = rules.storm_ticks if state.phase == &"storm" else rules.storm_cooldown
		var half: float = PI*clampf(float(state.remaining)/maxi(1,duration),0,1)
		GROUND_GEOMETRY.arc(mesh,origin,style.storm_ring_radius_m,half,half,style.storm_ring_width_m,Color(color,0.5),12)
	if state.weapon == &"bubble_cannon" and state.source_id == 1:
		var center: Vector3 = state.get("bubble_aim",state.position)+Vector3.UP*style.ground_height
		var radius: float = preload("res://content/rules/bubble.tres").field_radius if state.phase == &"bubble" else style.bubble_plan_radius_m
		GROUND_GEOMETRY.arc(mesh,center,radius,0,PI,style.line_width*2,style.bubble_color)
	mesh.surface_end()
	(_nodes[state.source_id] as MeshInstance3D).mesh = mesh

func _draw_zones(zones: Array) -> void:
	var mesh: ImmediateMesh = _mesh()
	for zone: Dictionary in zones:
		GROUND_GEOMETRY.arc(mesh,zone.position+Vector3.UP*style.ground_height,rules.smoke_radius,0,PI,style.line_width*2,style.escape_color)
	mesh.surface_end()
	_zones.mesh = mesh

func _remove(id: int) -> void:
	if _nodes.has(id):
		(_nodes[id] as Node).queue_free()
		_nodes.erase(id)
	_guard_hits.erase(id)

func clear() -> void:
	_art.clear()
	_signatures.clear()
	_frames.clear()
	for id: int in _nodes.keys(): _remove(id)
	_zones.mesh = null
	_guard_hits.clear()
