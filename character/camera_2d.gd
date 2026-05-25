extends Camera2D

func shake(magnitude: float = 0.7) -> void:
	for i in 8:
		offset = Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
		await get_tree().create_timer(0.02, true, false, true).timeout
	offset = Vector2.ZERO
