class_name PostureArc extends Node2D

@export var radius: float = 14.0
@export var arc_width: float = 3.0
@export var background_color: Color = Color(0.15, 0.15, 0.15, 0.55)
@export var fill_color: Color = Color(1.0, 0.85, 0.15, 1.0)
@export var critical_color: Color = Color(1.0, 0.25, 0.2, 1.0)
@export var critical_threshold: float = 0.75

var _ratio: float = 0.0

func set_posture_ratio(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	visible = _ratio > 0.0
	queue_redraw()

func _draw() -> void:
	if _ratio <= 0.0:
		return
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, background_color, arc_width, true)
	var start_angle := -PI / 2.0
	var end_angle := start_angle + TAU * _ratio
	var color := critical_color if _ratio >= critical_threshold else fill_color
	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 32, color, arc_width, true)
