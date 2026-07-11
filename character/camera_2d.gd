extends Camera2D

var _shake_tween: Tween

func shake(magnitude: float = 0.7, duration: float = 0.2) -> void:
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
		
	_shake_tween = create_tween()
	var steps := int(duration / 0.02)
	for i in steps:
		var t := float(i) / steps
		var decay := 1.0 - t
		var off := Vector2(
			randf_range(-magnitude, magnitude) * decay,
			randf_range(-magnitude, magnitude) * decay
		 )
		_shake_tween.tween_property(self, "offset", off, 0.02)
	_shake_tween.tween_property(self, "offset", Vector2.ZERO, 0.02)
