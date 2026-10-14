extends Node3D
class_name AbilitySignatureEffects
## Readable geometric silhouettes, driven exclusively by committed session ticks.

var style: WeaponVisualStyle = preload("res://content/presentation/weapon_visuals.tres")
var rules: BasicAbilityRules = preload("res://content/rules/basic_abilities.tres")
var bubble_rules: BubbleRules = preload("res://content/rules/bubble.tres")
var colors: AbilityEffectStyle = preload("res://content/presentation/ability_effects.tres")
var actors: Dictionary = {}
var bursts: Array[Dictionary] = []
var _seen: Dictionary = {}
var _material: StandardMaterial3D
var _tick: int = -1

func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED

func on_event(event: Dictionary) -> void:
	var tick: int = event.tick
	if tick < _tick: return
	_tick = tick
	_age(tick)
	if event.kind == &"match_finished":
		clear()
		return
	if event.kind == &"ability_state":
		var id: int = event.source_id
		if not event.alive:
			_remove_actor(id)
			return
		if not actors.has(id):
			if actors.size() >= style.max_signatures: return
			actors[id] = _node()
		_draw_state(actors[id],event)
	elif event.kind == &"ability_fired":
		var key: String = "%s:%s:%s" % [event.source_id,event.ability,tick]
		if _seen.has(key) or bursts.size() >= style.max_signatures: return
		_seen[key] = tick+style.signature_ticks
		var node: MeshInstance3D = _node()
		var burst: Dictionary = {"node":node,"event":event.duplicate(),"start":tick,"until":tick+style.signature_ticks}
		bursts.append(burst)
		_draw_burst(burst,tick)

func _node() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _mesh() -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,_material)
	_triangle(mesh,Vector3.ZERO,Vector3.RIGHT*0.001,Vector3.UP*0.001,Color(0,0,0,0))
	return mesh

func _draw_state(node: MeshInstance3D, state: Dictionary) -> void:
	var mesh: ImmediateMesh = _mesh()
	var aim := Vector3(sin(state.yaw),0,-cos(state.yaw))
	var right := Vector3(-aim.z,0,aim.x)
	var muzzle: Vector3 = state.get("visual_muzzle_position",state.position+aim*ProjectileSystem.MUZZLE_OFFSET+Vector3.UP*ProjectileSystem.SHOT_HEIGHT)
	var center: Vector3 = state.position+Vector3.UP*0.12
	var pulse: float = 0.75+0.25*sin(float(state.tick)*0.4)
	match state.phase:
		&"breach":
			var progress: float = clampf(1.0-float(state.remaining)/rules.breach_charge,0,1)
			for i: int in range(2):
				var radius: float = style.breach_ring_radius*(1.5-progress*0.7)+i*0.17
				_circle(mesh,muzzle-aim*i*0.22,right,Vector3.UP,radius,Color(colors.breach_color,0.9),state.tick*0.08*(i*2-1))
			for side: int in [-1,1]:
				_line(mesh,muzzle+right*side*(0.9-progress*0.5),muzzle+right*side*0.16,colors.breach_color)
		&"storm":
			for side: int in [-1,1]:
				var start: Vector3 = state.position+right*side*0.62+Vector3.UP*0.85
				var tip: Vector3 = start-aim*style.storm_jet_length*pulse
				_triangle(mesh,start+Vector3.UP*0.14,start-Vector3.UP*0.14,tip,colors.storm_color)
				_line(mesh,start+aim*0.1,tip+right*side*0.16,Color("fff2c4"))
		&"shock":
			var progress: float = clampf(1.0-float(state.remaining)/rules.shock_charge,0,1)
			_arc(mesh,center,rules.shock_range*(1.0-progress*0.5),state.locked_yaw,deg_to_rad(rules.shock_half_angle),Color(colors.shock_color,0.9),0.22)
			for i: int in range(5):
				var angle: float = state.locked_yaw+deg_to_rad(rules.shock_half_angle)*(float(i)/2-1)
				var dir := Vector3(sin(angle),0,-cos(angle))
				_line(mesh,center+dir*(1.1+progress),center+dir*(1.5+progress),colors.shock_color)
		&"bubble":
			var progress: float = clampf(1.0-float(state.remaining)/bubble_rules.charge_ticks,0,1)
			var index: int = 0
			for p: Vector3 in state.get("bubble_plan",PackedVector3Array()):
				var height: float = style.bubble_marker_height*clampf(progress*bubble_rules.count-index,0.15,1)
				var base := Vector3(p.x,0.12,p.z)
				_circle(mesh,base,Vector3.RIGHT,Vector3.BACK,colors.bubble_plan_radius_m,colors.bubble_color)
				for side: int in [-1,1]: _line(mesh,base+right*side*0.36,base+right*side*0.36+Vector3.UP*height,colors.bubble_color)
				index += 1
	if state.get("cruise",false):
		var front := Vector3(sin(state.body_yaw),0,-cos(state.body_yaw))
		var lateral := Vector3(-front.z,0,front.x)
		for side: int in [-1,1]:
			var p: Vector3 = center-front*0.7+lateral*side*0.5+Vector3.UP*0.20
			_triangle(mesh,p+lateral*0.14,p-lateral*0.14,p-front*1.3*pulse,colors.cruise_color)
	mesh.surface_end()
	node.mesh = mesh

func _draw_burst(burst: Dictionary, tick: int) -> void:
	var mesh: ImmediateMesh = _mesh()
	var event: Dictionary = burst.event
	var t: float = clampf(float(tick-burst.start)/style.signature_ticks,0,1)
	var ease: float = 1-pow(1-t,3)
	var p: Vector3 = event.position
	match event.ability:
		&"breach":
			var aim := Vector3(sin(event.yaw),0,-cos(event.yaw))
			var right := Vector3(-aim.z,0,aim.x)
			_circle(mesh,p,right,Vector3.UP,lerpf(0.25,style.breach_release_radius,ease),Color(colors.breach_color,1-t))
			_circle(mesh,p-aim*0.2,right,Vector3.UP,lerpf(0.15,style.breach_release_radius*0.65,ease),Color.WHITE*(1-t))
		&"shock":
			for i: int in range(3):
				var progress: float = clampf((t-float(i)*0.12)*1.5,0,1)
				var radius: float = rules.shock_range*(1-pow(1-progress,2))
				_arc(mesh,p+Vector3.UP*0.13,radius,event.yaw,deg_to_rad(rules.shock_half_angle),Color(colors.shock_color,(1-progress)*0.95),style.shock_height*(1-progress))
			for i: int in range(7):
				var angle: float = event.yaw+deg_to_rad(rules.shock_half_angle)*0.8*(float(i)/3-1)
				var radial := Vector3(sin(angle),0,-cos(angle))
				var tangent := Vector3(-radial.z,0,radial.x)
				var shard: Vector3 = p+radial*(rules.shock_range-0.25)*ease+Vector3.UP*(0.2+sin(t*PI)*style.shock_height)
				_triangle(mesh,shard-tangent*0.12,shard+tangent*0.12,shard+radial*0.2+Vector3.UP*0.18,Color(colors.shock_color,1-t))
		&"bubble":
			_circle(mesh,p+Vector3.UP*0.15,Vector3.RIGHT,Vector3.BACK,0.4+ease*0.7,Color(colors.bubble_color,1-t))
	mesh.surface_end()
	(burst.node as MeshInstance3D).mesh = mesh

func _age(tick: int) -> void:
	for key: String in _seen.keys():
		if tick >= int(_seen[key]): _seen.erase(key)
	var active: Array[Dictionary] = []
	for burst: Dictionary in bursts:
		if tick >= burst.until: (burst.node as Node).queue_free()
		else:
			_draw_burst(burst,tick)
			active.append(burst)
	bursts = active

func _remove_actor(id: int) -> void:
	if actors.has(id):
		(actors[id] as Node).queue_free()
		actors.erase(id)
	var active: Array[Dictionary] = []
	for burst: Dictionary in bursts:
		if burst.event.source_id == id: (burst.node as Node).queue_free()
		else: active.append(burst)
	bursts = active

func clear() -> void:
	for node: Node in actors.values(): node.queue_free()
	for burst: Dictionary in bursts: (burst.node as Node).queue_free()
	actors.clear()
	bursts.clear()
	_seen.clear()
	_tick = -1

func _circle(mesh: ImmediateMesh, p: Vector3, x: Vector3, y: Vector3, radius: float, color: Color, phase: float = 0.0) -> void:
	for i: int in range(24):
		var a: float = TAU*i/24+phase
		var b: float = TAU*(i+0.75)/24+phase
		_line(mesh,p+(x*cos(a)+y*sin(a))*radius,p+(x*cos(b)+y*sin(b))*radius,color)

func _arc(mesh: ImmediateMesh, p: Vector3, radius: float, yaw: float, half: float, color: Color, height: float) -> void:
	for i: int in range(24):
		var a: float = yaw-half+half*2*i/24
		var b: float = yaw-half+half*2*(i+1)/24
		var start: Vector3 = p+Vector3(sin(a),0,-cos(a))*radius
		var end: Vector3 = p+Vector3(sin(b),0,-cos(b))*radius
		_line(mesh,start+Vector3.UP*height,end+Vector3.UP*height,color)
		_triangle(mesh,start,end,end+Vector3.UP*height,Color(color,color.a*0.28))
		_triangle(mesh,start,end+Vector3.UP*height,start+Vector3.UP*height,Color(color,color.a*0.28))

func _line(mesh: ImmediateMesh, start: Vector3, end: Vector3, color: Color) -> void:
	var side: Vector3 = (end-start).cross(Vector3.UP)
	if side.length_squared() < 0.000001: side = Vector3.RIGHT
	side = side.normalized()*style.signature_width*0.5
	_triangle(mesh,start-side,start+side,end+side,color)
	_triangle(mesh,start-side,end+side,end-side,color)

func _triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_add_vertex(c)
