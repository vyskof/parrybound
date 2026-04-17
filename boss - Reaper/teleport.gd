extends State

var can_transition: bool = false

func enter():
	super.enter()
	animation_player.play("skill")
	await animation_player.animation_finished
	can_transition = true

func teleport():
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * 50
	owner.position = character.position + offset

func transition():
	if can_transition:
		get_parent().change_state("Attack")
		can_transition = false
