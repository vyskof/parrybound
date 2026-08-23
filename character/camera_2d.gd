extends Camera2D

var _intro_active: bool = false

var _shake_strength: float = 0.0
const SHAKE_DECAY := 5.0   

func _process(delta: float) -> void:
	if _shake_strength <= 0.0:
		return
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	_shake_strength = maxf(0.0, _shake_strength - SHAKE_DECAY * delta)
	if _shake_strength <= 0.0:
		offset = Vector2.ZERO

func shake(magnitude: float = 0.7) -> void:
	_shake_strength = maxf(_shake_strength, magnitude)


func zoom_pulse(target_zoom: Vector2 = Vector2(0.88, 0.88), duration: float = 0.4) -> void:
	if _intro_active:
		return   # boss intro už řídí zoom — nepřepisovat souběžným pulsem
	var tween := create_tween()
	tween.tween_property(self, "zoom", target_zoom, duration * 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "zoom", Vector2.ONE, duration * 0.7)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


var _intro_original_position: Vector2 = Vector2.ZERO

func build_boss_intro_tween(boss_position: Vector2, hold_duration: float = 1.2) -> Tween:
	_intro_active = true
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
	_intro_active = false
