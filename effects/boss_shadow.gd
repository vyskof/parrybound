class_name BossShadow extends Node2D

@export var shadow_size: Vector2 = Vector2(22.0, 7.0)
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.35)

var _base_size: Vector2

func _ready() -> void:
	z_index = -1
	_base_size = shadow_size

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, shadow_size)
	draw_circle(Vector2.ZERO, 1.0, shadow_color)

func pulse(intensity: float = 1.3, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_method(_set_size_scale, 1.0, intensity, duration * 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_size_scale, intensity, 1.0, duration * 0.7)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _set_size_scale(scale_mult: float) -> void:
	shadow_size = _base_size * scale_mult
	queue_redraw()
