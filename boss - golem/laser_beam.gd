extends State

@onready var pivot: Node2D = $"../../pivot"
@onready var hitbox: Hitbox = owner.find_child("Hitbox")
var can_transition: bool = false

const LASER_DAMAGE:         float = 50.0
const LASER_POSTURE_DAMAGE: float = 30.0
const LASER_KNOCKBACK:      float = 0.0


func enter() -> void:
	super.enter()
	_setup_hitbox()
	await _play("laser_cast")
	await _play("laser")
	can_transition = true

func _setup_hitbox() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.damage          = LASER_DAMAGE
		hitbox.combat_data.posture_damage  = LASER_POSTURE_DAMAGE
		hitbox.combat_data.knockback_force = LASER_KNOCKBACK
	else:
		hitbox.damage = LASER_DAMAGE


func _play(anim_name: String) -> void:
	animation_player.play(anim_name)
	await animation_player.animation_finished

func set_target()-> void:
	pivot.rotation = (owner.direction - pivot.position).angle()

func transition()-> void:
	if can_transition:
		can_transition = false
		get_parent().change_state("Dash")
