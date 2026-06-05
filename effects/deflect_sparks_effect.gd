extends CPUParticles2D

func init(color: Color, scale_mult: float = 1.0, size_mult: float = 1.0) -> void:
	modulate = color
	amount           = int(15 * scale_mult)
	initial_velocity_min = 60.0  * scale_mult
	initial_velocity_max = 120.0 * scale_mult
	scale_amount_min = 0.5 * scale_mult
	scale_amount_max = 0.5 * scale_mult
	emitting = true
	await get_tree().create_timer(lifetime + 0.1, true, false, true).timeout
	queue_free()
	
	
	
