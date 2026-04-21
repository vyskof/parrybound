class_name Hitbox extends Area2D

@export var combat_data: CombatData

@export var stores_hit_targets: bool = true

var hit_targets: Array[Node] = []

var damage: float:
	get:
		return combat_data.damage if combat_data else _fallback_damage
	set(value):
		_fallback_damage = value

var _fallback_damage: float = 0.0

func can_hit(target: Node) -> bool:
	if not stores_hit_targets:
		return true
	return target not in hit_targets

func register_hit(target: Node) -> void:
	if stores_hit_targets:
		hit_targets.append(target)

func clear_hit_targets() -> void:
	hit_targets.clear()
