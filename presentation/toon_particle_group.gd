extends Node3D
## Independent, deterministic cartoon fragments + one delayed dust lobe. Cosmetic only.
const FX = preload("res://presentation/toon_fx_materials.gd")
var particles: Array[Dictionary] = []
var origin: Vector3
var tuning: SkillFlipbookStyle

func configure(center: Vector3, direction: Vector3, style: SkillFlipbookStyle, seed_value: int) -> void:
	origin = center
	tuning = style
	var forward: Vector3 = Vector3(direction.x,0,direction.z).normalized()
	if forward.length_squared() < 0.01: forward = Vector3.FORWARD
	var right := Vector3(-forward.z,0,forward.x)
	for i: int in range(tuning.debris_count):
		var split: float = float(i)-float(tuning.debris_count-1)*0.5
		var sprite: Sprite3D = FX.create(&"debris",&"metal",i%3,tuning.debris_width)
		add_child(sprite)
		var speed: float = tuning.debris_speed*(0.8+float((seed_value+i*7)%5)*0.1)
		var velocity: Vector3 = (forward+right*split*tuning.debris_spread).normalized()*speed+Vector3.UP*(0.7+float(i)*0.35)
		particles.append({"node":sprite,"velocity":velocity,"spin":float(1 if i%2 == 0 else -1)*(2.5+float(i)*1.2),"dust":false})
	var smoke: Sprite3D = FX.create(&"smoke",&"dust",1,tuning.debris_smoke_width)
	add_child(smoke)
	particles.append({"node":smoke,"velocity":forward*0.3+Vector3.UP*0.35,"spin":0.2,"dust":true})
	step(0)

func step(age: int) -> void:
	var life: float = clampf(float(age)/maxi(1,tuning.debris_ticks),0,1)
	var seconds: float = float(age)/60.0
	for particle: Dictionary in particles:
		var sprite: Sprite3D = particle.node
		var velocity: Vector3 = particle.velocity
		if particle.dust:
			sprite.position = origin+velocity*seconds
			sprite.scale = Vector3.ONE*lerpf(0.4,1.0,life)
			sprite.modulate.a = tuning.debris_smoke_opacity*minf(1,float(age)/3.0)*(1.0-life)
		else:
			sprite.position = origin+velocity*seconds+Vector3.DOWN*tuning.debris_gravity*seconds*seconds*0.5
			sprite.position.y = maxf(0.08,sprite.position.y)
			sprite.scale = Vector3.ONE*lerpf(1.0,0.85,life)
			sprite.modulate.a = 1.0-smoothstep(0.7,1.0,life)
			(sprite.material_override as ShaderMaterial).set_shader_parameter("spin",particle.spin*seconds)
		FX.advance(sprite,life)
