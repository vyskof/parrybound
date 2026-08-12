class_name VisualFX

static func squash_stretch(target: Node2D, squash_scale: Vector2 = Vector2(1.15, 0.75), duration_in: float = 0.12, duration_out: float = 0.35) -> Tween:
	if not target:
		return null
	var tween := target.create_tween()
	tween.tween_property(target, "scale", squash_scale, duration_in).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "scale", Vector2.ONE, duration_out)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween
