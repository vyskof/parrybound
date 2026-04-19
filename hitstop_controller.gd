class_name HitstopController extends Node

@export var animation_targets: Array[Node] = []

var _freeze_count: int = 0

func freeze(duration: float) -> void:
	_freeze_count += 1
	_set_speed(0.0)
	await get_tree().create_timer(duration, true, false, true).timeout
	_freeze_count -= 1
	if _freeze_count <= 0:
		_freeze_count = 0
		_set_speed(1.0)

func cancel() -> void:
	_freeze_count = 0
	_set_speed(1.0)

func is_frozen() -> bool:
	return _freeze_count > 0

func _set_speed(speed: float) -> void:
	for target in animation_targets:
		if target is AnimationPlayer:
			(target as AnimationPlayer).speed_scale = speed
		elif target is AnimationTree:
			(target as AnimationTree).set(
			"parameters/TimeScale/scale", 
			speed
			)

func _ready() -> void:
	if animation_targets.is_empty():
		push_warning(
			"HitstopController na '%s' nemá žádné animation_targets!"
			% get_parent().name
			)
