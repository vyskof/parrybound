extends Camera2D

func shake() -> void:
	for i in 8:
		offset = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		await get_tree().create_timer(0.02, true, false, true).timeout
	offset = Vector2.ZERO
