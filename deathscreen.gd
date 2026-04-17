extends CanvasLayer

func _ready() -> void:
	get_tree().paused = true

func _on_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()
