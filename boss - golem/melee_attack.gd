extends State

@onready var hitbox: Hitbox = owner.find_child("Hitbox")
var is_active: bool = false

const MELEE_DAMAGE:         float = 10.0
const MELEE_POSTURE_DAMAGE: float = 12.0
const MELEE_KNOCKBACK:      float = 80.0


func enter() -> void:
	super.enter()
	is_active = true
	owner.set_physics_process(true)
	_setup_hitbox()
	combo()

func exit() -> void:
	super.exit()
	owner.set_physics_process(false)
	is_active = false
	if hitbox:
		hitbox.clear_hit_targets()

func _setup_hitbox() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.damage          = MELEE_DAMAGE
		hitbox.combat_data.posture_damage  = MELEE_POSTURE_DAMAGE
		hitbox.combat_data.knockback_force = MELEE_KNOCKBACK
	else:
		hitbox.damage = MELEE_DAMAGE

func attack() -> void:
	animation_player.play("melee_attack")
	await animation_player.animation_finished


func combo() -> void:
	while is_active:
		await attack()
		if owner.direction.length() > 30.0:
			get_parent().change_state("Follow")
			return

func transition() -> void:
	pass
