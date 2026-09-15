class_name DeathScreen extends CanvasLayer

@onready var _color_rect: ColorRect = $ColorRect
@onready var _label: Label = $Label
@onready var _button: Button = $Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	_color_rect.modulate.a = 0.0
	_label.modulate.a = 0.0
	_button.visible = false
	_button.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_label, "modulate:a", 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.5)
	tween.tween_callback(_reveal_button)

func _reveal_button() -> void:
	_button.visible = true
	var button_tween := create_tween()
	button_tween.tween_property(_button, "modulate:a", 1.0, 0.3)

func _on_button_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()
