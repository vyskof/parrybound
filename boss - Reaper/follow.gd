extends State

func enter():
	super.enter()
	owner.set_physics_process(true)
	animation_player.play("idle")

func exit():
	super.exit()
	owner.set_physics_process(false)

func transition():
	if owner.direction.length() < owner.attack_range:
		get_parent().change_state("Attack")
		return
	if owner.direction.length() > owner.far_range:
		var chance = randi() % 2
		match chance:
			0:
				get_parent().change_state("Teleport")
			1:
				get_parent().change_state("SpawnMinion")
