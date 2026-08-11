extends Node

var _freeze_count: int = 0
var _active_scale: float = 1.0

func freeze(duration: float, time_scale: float = 0.05) -> void:
	if duration <= 0.0:
		return
	_freeze_count += 1
	_active_scale = time_scale if _freeze_count == 1 else min(_active_scale, time_scale)
	Engine.time_scale = _active_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	_freeze_count -= 1
	if _freeze_count <= 0:
		_freeze_count = 0
		_active_scale = 1.0
		Engine.time_scale = 1.0

func cancel() -> void:
	_freeze_count = 0
	_active_scale = 1.0
	Engine.time_scale = 1.0

func is_frozen() -> bool:
	return _freeze_count > 0
