extends CPUParticles2D

func _ready() -> void:
	emitting = true
	await get_tree().create_timer(lifetime + 0.1, true, false, true).timeout
	queue_free()
