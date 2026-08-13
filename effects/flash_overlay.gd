extends CanvasLayer

@onready var _rect: ColorRect = $Rect

func flash(color: Color = Color(1, 1, 1, 1), peak_alpha: float = 0.5, duration: float = 0.25) -> void:
	if not _rect:
		return
	_rect.color = color
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", peak_alpha, duration * 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_rect, "modulate:a", 0.0, duration * 0.85)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
