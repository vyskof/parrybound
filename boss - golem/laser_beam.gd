extends State

@onready var pivot: Node2D = $"../../pivot"
@onready var hitbox: Hitbox = owner.find_child("Hitbox")
var can_transition: bool = false

const LASER_DAMAGE:         float = 50.0
const LASER_POSTURE_DAMAGE: float = 30.0
const LASER_KNOCKBACK:      float = 0.0

const PerilousWarning := preload("res://effects/perilous_warning.tscn")
var _current_warning: Node2D = null


func enter() -> void:
	super.enter()
	_setup_hitbox()
	_begin_perilous_telegraph()
	await _play("laser_cast")
	await _play("laser")
	_clear_perilous_state()
	can_transition = true

func exit() -> void:
	super.exit()
	_clear_perilous_state()

func _setup_hitbox() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.damage          = LASER_DAMAGE
		hitbox.combat_data.posture_damage  = LASER_POSTURE_DAMAGE
		hitbox.combat_data.knockback_force = LASER_KNOCKBACK
	else:
		hitbox.damage = LASER_DAMAGE

func _begin_perilous_telegraph() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.is_unblockable = true
		hitbox.combat_data.perilous_type  = CombatData.PerilousType.THRUST

	_current_warning = PerilousWarning.instantiate()
	owner.add_child(_current_warning)
	_current_warning.position = Vector2(0, -90)

func _clear_perilous_state() -> void:
	if hitbox.combat_data:
		hitbox.combat_data.is_unblockable = false
		hitbox.combat_data.perilous_type  = CombatData.PerilousType.NONE

	if is_instance_valid(_current_warning):
		_current_warning.queue_free()
		_current_warning = null

func _play(anim_name: String) -> void:
	animation_player.play(anim_name)
	await animation_player.animation_finished

func set_target() -> void:
	pivot.rotation = (owner.direction - pivot.position).angle()

func transition() -> void:
	if can_transition:
		can_transition = false
		get_parent().change_state("Dash")
