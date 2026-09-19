extends Camera2D

var _intro_active: bool = false


@export var max_offset: float = 6.0          
@export var max_rotation_deg: float = 0.35   
@export var trauma_falloff: float = 2.2      
@export var kick_recovery: float = 30.0      

const NOISE_SPEED := 32.0
const NOISE_GAIN := 2.2  

var _trauma: float = 0.0
var _kick: Vector2 = Vector2.ZERO
var _noise := FastNoiseLite.new()
var _noise_time: float = 0.0


func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.6



func shake(magnitude: float = 0.4, direction: Vector2 = Vector2.ZERO, kick: float = 0.0) -> void:
	_trauma = minf(_trauma + magnitude, 1.0)
	if direction != Vector2.ZERO and kick > 0.0:
		_kick += direction.normalized() * kick


func _process(delta: float) -> void:
	if _trauma <= 0.0 and _kick.is_zero_approx():
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
			rotation = 0.0
		return

	_noise_time += delta * NOISE_SPEED
	var amount := _trauma * _trauma
	var wobble := Vector2(
		clampf(_noise.get_noise_2d(_noise_time, 0.0) * NOISE_GAIN, -1.0, 1.0),
		clampf(_noise.get_noise_2d(0.0, _noise_time) * NOISE_GAIN, -1.0, 1.0)
	)
	offset = wobble * max_offset * amount + _kick
	rotation = deg_to_rad(max_rotation_deg) * amount * clampf(_noise.get_noise_2d(_noise_time, 100.0) * NOISE_GAIN, -1.0, 1.0)

	_trauma = maxf(_trauma - trauma_falloff * delta, 0.0)
	_kick = _kick.move_toward(Vector2.ZERO, kick_recovery * delta)


func zoom_pulse(target_zoom: Vector2 = Vector2(0.88, 0.88), duration: float = 0.4) -> void:
	if _intro_active:
		return  
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
