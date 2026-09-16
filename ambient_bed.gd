extends AudioStreamPlayer2D

@export var fade_duration: float = 1.2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var target_volume_db := volume_db
	volume_db = -80.0
	if stream:
		play()
	var tween := create_tween()
	tween.tween_property(self, "volume_db", target_volume_db, fade_duration)\
		.set_trans(Tween.TRANS_SINE)

func _exit_tree() -> void:
	stop()
