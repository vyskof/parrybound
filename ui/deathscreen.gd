extends CanvasLayer

func _ready() -> void:
	get_tree().paused = true

func _on_button_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()
