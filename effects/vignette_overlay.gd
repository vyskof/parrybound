extends CanvasLayer

@export var default_intensity: float = 0.4

@onready var _rect: ColorRect = $Rect

func _ready() -> void:
	set_intensity(default_intensity)

func set_intensity(value: float) -> void:
	if _rect and _rect.material:
		_rect.material.set_shader_parameter("intensity", value)

func pulse(peak_intensity: float, duration: float = 0.3) -> void:
	if not _rect or not _rect.material:
		return
	var tween := create_tween()
	tween.tween_method(_apply_intensity, default_intensity, peak_intensity, duration * 0.3)
	tween.tween_method(_apply_intensity, peak_intensity, default_intensity, duration * 0.7)

func _apply_intensity(value: float) -> void:
	if _rect and _rect.material:
		_rect.material.set_shader_parameter("intensity", value)
