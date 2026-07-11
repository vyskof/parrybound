extends State

func enter() -> void:
	super.enter()
	animation_player.play("glowing")
	await _dash()
	get_parent().change_state("Follow")

func _dash() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(owner, "position", character.position, 0.8)
	await tween.finished
