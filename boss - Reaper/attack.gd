extends State

var is_active: bool = false
@onready var hitbox: Hitbox = owner.find_child("Hitbox")

func enter():
	super.enter()
	is_active = true
	hitbox.damage = 20
	owner.set_physics_process(true)
	combo()

func exit():
	super.exit()
	owner.set_physics_process(false)
	is_active = false
	hitbox.clear_hit_targets() 

func attack(move = "1"):
	animation_player.speed_scale = 1.5 if owner.phase_two else 1.0
	animation_player.play("attack_" + move)
	await animation_player.animation_finished

func combo():
	while is_active:
		var move_set = []
		var combo_length = randi_range(1, 3) if not owner.phase_two else randi_range(2, 4)
		for i in combo_length:
			move_set.append(str(randi_range(1, 2)))

		for move in move_set:
			if not is_active: return
			await attack(move)
		
		var wait = randf_range(0.4, 0.9) if not owner.phase_two else randf_range(0.2, 0.4)
		await get_tree().create_timer(wait).timeout
		
		if owner.direction.length() > 40:
			get_parent().change_state("Follow")
			return

func transition():
	pass  
