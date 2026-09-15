extends CanvasLayer

const LORE_LINES := [
	"Loading...",
]

@onready var _rect: ColorRect = $Rect
@onready var _label: Label = $Label

var _busy: bool = false

func transition_to(scene_path: String, min_duration: float = 1.1) -> void:
	if _busy:
		return
	_busy = true

	_label.text = LORE_LINES[randi() % LORE_LINES.size()]

	var fade_in := create_tween()
	fade_in.tween_property(_rect, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	fade_in.parallel().tween_property(_label, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	await fade_in.finished

	get_tree().call_deferred("change_scene_to_file", scene_path)
	await get_tree().create_timer(min_duration, true, false, true).timeout

	var fade_out := create_tween()
	fade_out.tween_property(_rect, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	fade_out.parallel().tween_property(_label, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	await fade_out.finished

	_busy = false
