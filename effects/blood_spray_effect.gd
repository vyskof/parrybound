extends CPUParticles2D

const BASE_AMOUNT := 14

func init(hit_direction: Vector2, amount_mult: float = 1.0) -> void:
	if hit_direction != Vector2.ZERO:
		direction = hit_direction.normalized()
	amount = int(BASE_AMOUNT * amount_mult)
	emitting = true
	await get_tree().create_timer(lifetime + 0.1, true, false, true).timeout
	queue_free()
