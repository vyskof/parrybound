class_name BossFollowState extends State

var _far_cooldown: float = 0.0


func enter() -> void:
	super.enter()
	owner.set_physics_process(true)
	animation_player.play("idle")


func exit() -> void:
	super.exit()
	owner.set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _far_cooldown > 0.0:
		_far_cooldown -= delta
	super._physics_process(delta)


func transition() -> void:
	var distance: float = owner.direction.length()
	if distance < owner.attack_range:
		get_parent().change_state("Attack")
		return
	if distance <= owner.far_range:
		return

	if owner.far_states.is_empty():
		get_parent().change_state("Attack")
		return
	if _far_cooldown > 0.0:
		return
	_far_cooldown = owner.far_state_cooldown
	var pick: StringName = owner.far_states[randi() % owner.far_states.size()]
	get_parent().change_state(String(pick))
