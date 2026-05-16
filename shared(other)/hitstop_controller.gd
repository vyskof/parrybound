class_name HitstopController extends Node

var _freeze_count: int = 0

func freeze(duration: float) -> void:
	if duration <= 0.0:
		return
	_freeze_count += 1
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	_freeze_count -= 1
	if _freeze_count <= 0:
		_freeze_count = 0
		Engine.time_scale = 1.0

func cancel() -> void:
	_freeze_count = 0
	Engine.time_scale = 1.0

func is_frozen() -> bool:
	return _freeze_count > 0
