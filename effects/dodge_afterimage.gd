extends Sprite2D

func init(source: Sprite2D, tint: Color = Color(0.6, 0.8, 1.0, 0.5), fade_duration: float = 0.1) -> void:
	texture  = source.texture
	hframes  = source.hframes
	vframes  = source.vframes
	frame    = source.frame
	flip_h   = source.flip_h
	
	global_position = source.global_position
	
	modulate = tint
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	queue_free()
