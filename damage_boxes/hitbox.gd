class_name Hitbox extends Area2D

@export var damage: = 50


@export var stores_hit_targets: bool = true
var hit_targets: Array = []

func is_hitbox() -> bool:
	return true

func clear_hit_targets() -> void:
	hit_targets.clear()

func register_hit(target: Area2D) -> void:
	if not stores_hit_targets:
		return
	if target in hit_targets:
		return
	hit_targets.append(target)
