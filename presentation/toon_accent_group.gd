extends Node3D
## Small constituent particles, never repeated whole effects. Tick-analytic and cosmetic.
const FX = preload("res://presentation/toon_fx_materials.gd")
var particles: Array[Dictionary] = []
var duration: int
var gravity: float
var opacity: float
var origin: Vector3
var mode: StringName

func configure(kind: StringName, center: Vector3, direction: Vector3, count: int, width: float, speed: float, ticks: int, fall: float = 0.0, alpha: float = 1.0) -> void:
	mode = kind
	origin = center
	duration = maxi(1,ticks)
	gravity = fall
	opacity = alpha
	var forward := Vector3(direction.x,0,direction.z).normalized()
	if forward.length_squared() < 0.01: forward = Vector3.FORWARD
	var right := Vector3(-forward.z,0,forward.x)
	for i: int in range(clampi(count,1,3)):
		var side: float = 0.0 if count == 1 else lerpf(-1.0,1.0,float(i)/float(clampi(count,1,3)-1))
		var sprite: Sprite3D
		if kind == &"dust": sprite = FX.create(&"smoke",&"dust",i%3,width)
		elif kind == &"water": sprite = FX.water(width)
		else: sprite = FX.contact(width,&"guard" if kind == &"guard" else &"warm",2)
		add_child(sprite)
		var velocity: Vector3 = (forward*0.6+right*side*0.8)*speed+Vector3.UP*speed*0.45
		var offset := Vector3.ZERO
		if kind == &"reload":
			velocity = Vector3.UP*speed
			offset = right*side*0.66
		elif kind == &"dust": offset = right*side*0.5
		particles.append({"node":sprite,"velocity":velocity,"offset":offset})
	step(0)

func step(age: int) -> void:
	var life: float = clampf(float(age)/duration,0,1)
	var seconds: float = float(maxi(0,age))/60.0
	for particle: Dictionary in particles:
		var sprite: Sprite3D = particle.node
		sprite.position = origin+particle.offset+particle.velocity*seconds+Vector3.DOWN*gravity*seconds*seconds*0.5
		sprite.scale = Vector3.ONE*(lerpf(0.4,1.2,life) if mode == &"dust" else lerpf(1.0,0.5,life))
		sprite.modulate.a = opacity*(1.0-smoothstep(0.2,1.0,life))
		FX.advance(sprite,life)
