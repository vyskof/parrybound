extends CanvasLayer

@onready var _rect: ColorRect = $Rect
var _low_health_tween: Tween

func pulse(peak_intensity: float, duration: float = 0.35) -> void:
	if not _rect or not _rect.material:
		return
	var tween := create_tween()
	tween.tween_method(_apply_intensity, peak_intensity, 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func start_low_health_pulse() -> void:
	if _low_health_tween and _low_health_tween.is_running():
		return
	_low_health_tween = create_tween().set_loops()
	_low_health_tween.tween_method(_apply_intensity, 0.0, 0.35, 0.6).set_trans(Tween.TRANS_SINE)
	_low_health_tween.tween_method(_apply_intensity, 0.35, 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func stop_low_health_pulse() -> void:
	if _low_health_tween:
		_low_health_tween.kill()
		_low_health_tween = null
	_apply_intensity(0.0)

func _apply_intensity(value: float) -> void:
	if _rect and _rect.material:
		_rect.material.set_shader_parameter("intensity", value)
