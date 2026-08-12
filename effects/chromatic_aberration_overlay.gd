extends CanvasLayer

@onready var _rect: ColorRect = $Rect

func pulse(peak_amount: float = 0.006, duration: float = 0.25) -> void:
	if not _rect or not _rect.material:
		return
	var tween := create_tween()
	tween.tween_method(_apply_amount, 0.0, peak_amount, duration * 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(_apply_amount, peak_amount, 0.0, duration * 0.75)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _apply_amount(value: float) -> void:
	if _rect and _rect.material:
		_rect.material.set_shader_parameter("aberration_amount", value)
