extends State

@onready var hitbox: Hitbox = owner.find_child("Hitbox")
var is_active: bool = false

func enter():
	super.enter()
	is_active = true
	owner.set_physics_process(true)
	hitbox.damage = 10
	combo()

func exit():
	super.exit()
	owner.set_physics_process(false)
	is_active = false

func attack():
	animation_player.play("melee_attack")
	await animation_player.animation_finished

func combo():
	while is_active:
		await attack()
		if owner.direction.length() > 30:
			get_parent().change_state("Follow")
			return

func transition():
	pass
