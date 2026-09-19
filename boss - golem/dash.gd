extends State

var _tween: Tween = null


func enter() -> void:
	super.enter()
	animation_player.play("glowing")
	_dash()


func exit() -> void:
	super.exit()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null


func _dash() -> void:
	if not is_instance_valid(character):
		get_parent().change_state("Follow")
		return
	_tween = owner.create_tween()
	_tween.tween_property(owner, "global_position", character.global_position, 0.8)
	await _tween.finished
	if not is_active:
		return
	get_parent().change_state("Follow")
