extends Node3D
class_name AbilityEffects
## Draws only committed simulation events. Geometry never participates in collision.

var style: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var rules: BasicAbilityRules = preload("res://content/rules/basic_abilities.tres")
var _states: Dictionary = {}
var _nodes: Dictionary = {}
var _bursts: Array[Dictionary] = []
var _zones := MeshInstance3D.new()
var _material := StandardMaterial3D.new()
var _guard_hits: Dictionary = {}
var _tick: int = 0
var _art := AbilitySpriteEffects.new()

func _ready() -> void:
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(_zones)
	add_child(_art)

func on_event(event: Dictionary) -> void:
	_tick = event.tick
	_art.on_event(event)
	if event.kind == &"damage_applied" and event.get("guarded",false):
		_guard_hits[event.target_id] = _tick+style.guard_hit_ticks
	if event.kind == &"ability_state":
		_states[event.source_id] = event.duplicate()
		_draw_actor(event)
	elif event.kind == &"ability_zones":
		_draw_zones(event.zones)
	elif event.kind == &"ability_fired" and event.ability == &"shock":
		_bursts.append({"position":event.position,"yaw":event.yaw,"until":_tick+style.shock_visual_ticks,"source_id":event.source_id})
	elif event.kind == &"match_finished": clear()

func clear() -> void:
	_art.clear()
	for node: MeshInstance3D in _nodes.values(): node.mesh = null
	_zones.mesh = null
	_states.clear()
	_guard_hits.clear()
	_bursts.clear()

func _draw_actor(state: Dictionary) -> void:
	if not _nodes.has(state.source_id):
		var node := MeshInstance3D.new()
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		_nodes[state.source_id] = node
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_material)
	# A tiny transparent triangle keeps the surface valid in idle states.
	_triangle(mesh,Vector3.ZERO,Vector3.RIGHT*0.001,Vector3.FORWARD*0.001,Color(0,0,0,0))
	var origin: Vector3 = state.position+Vector3.UP*style.ground_height
	var front := Vector3(sin(state.body_yaw),0,-cos(state.body_yaw))
	var right := Vector3(-front.z,0,front.x)
	if state.alive:
		if state.cruise:
			for side: int in [-1,1]:
				var start: Vector3 = origin-front*0.6+right*side*0.32+Vector3.UP*0.2
				_triangle(mesh,start+right*0.10,start-right*0.10,start-front*style.trail_length,style.cruise_color)
			for i: int in range(3):
				var phase: float = float(_tick % 18)/18.0
				var p: Vector3 = origin-front*(0.9+(i+phase)*0.38)
				_line(mesh,p+right*0.16-front*0.15,p,style.cruise_color)
				_line(mesh,p-right*0.16-front*0.15,p,style.cruise_color)
		if state.get("escape_active",false):
			for side: int in [-1,1]:
				for i: int in range(3):
					var phase: float = float(_tick%18)/18.0
					var p: Vector3 = origin+right*side*style.escape_arrow_span_m-front*(i+phase)*style.escape_arrow_spacing_m
					_line(mesh,p-front*0.22+right*0.12,p,style.escape_color)
					_line(mesh,p-front*0.22-right*0.12,p,style.escape_color)
		if state.guard:
			var guard_color: Color = Color.WHITE if _tick < int(_guard_hits.get(state.source_id,0)) else style.guard_color
			_arc(mesh,origin,style.guard_radius_m,state.body_yaw,deg_to_rad(rules.guard_half_angle),guard_color,style.guard_height_m)
			for i: int in range(5):
				var angle: float = state.body_yaw+deg_to_rad(rules.guard_half_angle)*(i/2.0-1.0)
				var edge: Vector3 = origin+Vector3(sin(angle),0,-cos(angle))*style.guard_radius_m
				_line(mesh,edge,edge+Vector3.UP*style.guard_height_m,guard_color)

		if state.phase == &"breach":
			var aim := Vector3(sin(state.yaw),0,-cos(state.yaw))
			var progress: float = clampf(1.0-float(state.remaining)/rules.breach_charge,0,1)
			_line(mesh,origin+aim*0.8,origin+aim*rules.breach_range,Color(style.breach_color,0.4))
			var core: Vector3 = state.position+aim*ProjectileSystem.MUZZLE_OFFSET+Vector3.UP*ProjectileSystem.SHOT_HEIGHT
			_ring(mesh,core,style.charge_core_m*(1.1-progress*0.5),style.breach_color)
			for i: int in range(8):
				var angle: float = i*TAU/8.0+progress*0.5
				var ray := Vector3(sin(angle),0,cos(angle))
				_line(mesh,core+ray*style.charge_ray_m*(1.2-progress*0.5),core+ray*0.12,Color(style.breach_color,0.75))
		elif state.phase == &"shock":
			_sector(mesh,origin,rules.shock_range,state.locked_yaw,deg_to_rad(rules.shock_half_angle),Color(style.shock_color,0.17))
		elif state.phase == &"bubble":
			for p: Vector3 in state.get("bubble_plan",PackedVector3Array()):
				_ring(mesh,Vector3(p.x,style.ground_height,p.z),style.bubble_plan_radius_m,style.bubble_color)
		elif state.phase in [&"storm",&"cooling"]:
			_draw_storm(mesh,state)

	_bursts = _bursts.filter(func(burst: Dictionary) -> bool: return _tick < burst.until)
	for burst: Dictionary in _bursts:
		if state.source_id != burst.source_id: continue
		var progress: float = 1.0-float(burst.until-_tick)/style.shock_visual_ticks
		_arc(mesh,burst.position+Vector3.UP*0.12,rules.shock_range*(1.0-pow(1.0-progress,2)),burst.yaw,deg_to_rad(rules.shock_half_angle),Color(style.shock_color,1.0-progress),0.18)
	mesh.surface_end()
	(_nodes[state.source_id] as MeshInstance3D).mesh = mesh

func _draw_zones(zones: Array) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_material)
	_triangle(mesh,Vector3.ZERO,Vector3.RIGHT*0.001,Vector3.FORWARD*0.001,Color(0,0,0,0))
	for zone: Dictionary in zones:
		var p: Vector3 = zone.position+Vector3.UP*style.ground_height
		_sector(mesh,p,rules.smoke_radius,0,PI,style.smoke_color)
		_ring(mesh,p,rules.smoke_radius,Color(style.smoke_color,0.8))
		# The footprint is authoritative size; volume is supplied by layered alpha art.
	mesh.surface_end()
	_zones.mesh = mesh

func _ring(mesh: ImmediateMesh, p: Vector3, radius: float, color: Color) -> void:
	_arc(mesh,p,radius,0,PI,color,0)

func _arc(mesh: ImmediateMesh, p: Vector3, radius: float, yaw: float, half: float, color: Color, height: float) -> void:
	for i: int in range(36):
		var a: float = yaw-half+half*2*i/36.0
		var b: float = yaw-half+half*2*(i+1)/36.0
		var start: Vector3 = p+Vector3(sin(a),0,-cos(a))*radius
		var end: Vector3 = p+Vector3(sin(b),0,-cos(b))*radius
		if height > 0:
			_triangle(mesh,start,end,end+Vector3.UP*height,Color(color,0.32))
			_triangle(mesh,start,end+Vector3.UP*height,start+Vector3.UP*height,Color(color,0.32))
		_line(mesh,start,end,color)
		if height > 0: _line(mesh,start+Vector3.UP*height,end+Vector3.UP*height,color)

func _sector(mesh: ImmediateMesh, p: Vector3, radius: float, yaw: float, half: float, color: Color) -> void:
	for i: int in range(36):
		var a: float = yaw-half+half*2*i/36.0
		var b: float = yaw-half+half*2*(i+1)/36.0
		_triangle(mesh,p,p+Vector3(sin(a),0,-cos(a))*radius,p+Vector3(sin(b),0,-cos(b))*radius,color)
	_arc(mesh,p,radius,yaw,half,Color(color,0.85),0)
	for angle: float in [yaw-half,yaw+half]: _line(mesh,p,p+Vector3(sin(angle),0,-cos(angle))*radius,Color(color,0.85))

func _line(mesh: ImmediateMesh, start: Vector3, end: Vector3, color: Color) -> void:
	var normal: Vector3 = (end-start).cross(Vector3.UP)
	if normal.length_squared() < 0.000001: normal = (end-start).cross(Vector3.FORWARD)
	var side: Vector3 = normal.normalized()*style.line_width*0.5
	_triangle(mesh,start-side,start+side,end+side,color)
	_triangle(mesh,start-side,end+side,end-side,color)

func _triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_add_vertex(c)

func _draw_storm(mesh: ImmediateMesh, state: Dictionary) -> void:
	var active: bool = state.phase == &"storm"
	var color: Color = style.storm_color if active else style.cooling_color
	var center: Vector3 = state.position+Vector3.UP*style.storm_ring_height_m
	var duration: int = rules.storm_ticks if active else rules.storm_cooldown
	var fraction: float = clampf(float(state.remaining)/maxi(1,duration),0,1)
	var segments: int = style.storm_segments
	for i: int in range(segments):
		var angle: float = TAU*i/segments
		var radial := Vector3(sin(angle),0,-cos(angle))
		var tangent := Vector3(cos(angle),0,sin(angle))
		var p: Vector3 = center+radial*style.storm_ring_radius_m
		var lit: Color = color if float(i)/segments < fraction else Color(color,0.16)
		var inner: Vector3 = p-radial*style.storm_ring_width_m
		_triangle(mesh,inner-tangent*0.12,inner+tangent*0.12,p+tangent*0.12,lit)
		_triangle(mesh,inner-tangent*0.12,p+tangent*0.12,p-tangent*0.12,lit)
	var aim := Vector3(sin(state.yaw),0,-cos(state.yaw))
	var right := Vector3(-aim.z,0,aim.x)
	for side: int in [-1,1]:
		var p: Vector3 = state.position+right*side*style.storm_rail_offset_m+Vector3.UP*style.vent_height_m
		if active:
			var tip: Vector3 = p+aim*style.storm_rail_length_m
			_triangle(mesh,p-right*0.07,p+right*0.07,tip+right*0.07,color)
			_triangle(mesh,p-right*0.07,tip+right*0.07,tip-right*0.07,color)
		else:
			_line(mesh,p,p+aim*style.storm_rail_length_m,color)
			for i: int in range(3):
				var drift: float = float((_tick+i*8)%24)/24.0
				var start: Vector3 = p-aim*i*0.18+Vector3.UP*drift*style.vent_length_m
				_line(mesh,start,start+Vector3.UP*style.vent_length_m*0.5+right*side*0.18,Color(color,1.0-drift))
