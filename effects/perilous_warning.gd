extends Node2D

func _ready() -> void:
	var label := $Label
	var tween := create_tween().set_loops()
	tween.tween_property(label, "modulate:a", 0.25, 0.15)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
