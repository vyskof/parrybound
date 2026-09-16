class_name Hitbox extends Area2D

@export var combat_data: CombatData
var _fallback_damage: float = 10.0

const MIN_HIT_INTERVAL := 0.08

@export var stores_hit_targets: bool = true

var hit_targets: Array[Node] = []
var _last_hit_time: Dictionary = {}

var damage: float:
	get:
		return combat_data.damage if combat_data else _fallback_damage
	set(value):
		if combat_data:
			combat_data.damage = value
		else:
			_fallback_damage = value


func can_hit(target: Node) -> bool:
	if stores_hit_targets and target in hit_targets:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var last: float = _last_hit_time.get(target, -999.0)
	if now - last < MIN_HIT_INTERVAL:
		return false
	return true

signal hit_landed(target: Node)

func register_hit(target: Node) -> void:
	if stores_hit_targets:
		hit_targets.append(target)
	_last_hit_time[target] = Time.get_ticks_msec() / 1000.0
	hit_landed.emit(target)

func clear_hit_targets() -> void:
	hit_targets.clear()
