extends CanvasLayer

@onready var _label: Label = $Label
var _finished: bool = false

func set_boss_name(display_name: String) -> void:
	_label.text = display_name
	_label.modulate.a = 0.0
	_play()

func _play() -> void:
	var tween_in := create_tween()
	tween_in.tween_property(_label, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween_in.finished

	await get_tree().create_timer(1.0, true, false, true).timeout
	_fade_out_and_free(0.5)

func skip() -> void:
	_fade_out_and_free(0.15)

func _fade_out_and_free(duration: float) -> void:
	if _finished:
		return
	_finished = true
	var tween_out := create_tween()
	tween_out.tween_property(_label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	await tween_out.finished
	queue_free()
