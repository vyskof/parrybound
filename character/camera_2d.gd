extends Camera2D

func shake(magnitude: float = 0.7) -> void:
	for i in 8:
		offset = Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
		await get_tree().create_timer(0.02, true, false, true).timeout
	offset = Vector2.ZERO


var _intro_original_position: Vector2 = Vector2.ZERO

func build_boss_intro_tween(boss_position: Vector2, hold_duration: float = 1.2) -> Tween:
	_intro_original_position = position
	var start_global := global_position

	top_level = true
	global_position = start_global

	var mid_point := start_global.lerp(boss_position, 0.5)
	var hold_timer := get_tree().create_timer(hold_duration, true, false, true)

	var tween := create_tween()
	tween.tween_property(self, "global_position", mid_point, 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "zoom", Vector2(0.8, 0.8), 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_await(hold_timer.timeout)

	tween.tween_property(self, "global_position", start_global, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "zoom", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.finished.connect(_restore_after_intro)
	return tween

func skip_boss_intro(tween: Tween) -> void:
	if is_instance_valid(tween):
		tween.kill()
	_restore_after_intro()

func _restore_after_intro() -> void:
	top_level = false
	position = _intro_original_position
	zoom = Vector2.ONE
