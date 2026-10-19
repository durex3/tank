extends RefCounted
class_name MagazineState
## Per entity/life ammunition, independent from the input controller lease.

var capacity: int = 0
var rounds: int = 0
var reload_until: int = 0
var _life: int = -1
var _weapon: StringName
var _reload_ticks: int = 0

func step(weapon: WeaponDef, life: int, tick: int) -> void:
	if life != _life or _weapon != weapon.id:
		_life = life
		_weapon = weapon.id
		capacity = weapon.magazine_size
		rounds = capacity
		reload_until = 0
		_reload_ticks = BattleClock.seconds_to_ticks(weapon.reload_s) if capacity > 0 else 0
	if capacity > 0 and rounds == 0 and tick >= reload_until:
		rounds = capacity
		reload_until = 0

func consume(tick: int) -> void:
	if capacity == 0: return
	assert(rounds > 0)
	rounds -= 1
	if rounds == 0: reload_until = tick+_reload_ticks

func publish(source_id: int, tick: int, events: BattleEvents) -> void:
	if capacity > 0:
		events.publish(&"magazine_state",tick,{"source_id":source_id,"rounds":rounds,"capacity":capacity,"remaining":maxi(0,reload_until-tick)})
