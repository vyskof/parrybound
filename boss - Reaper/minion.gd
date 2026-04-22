extends CharacterBody2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var character = get_tree().get_first_node_in_group("player")
@onready var animation = $AnimatedSprite2D

func _ready() -> void:
	hurtbox.hurt.connect(take_damage)
	set_physics_process(false)
	await animation.animation_finished
	set_physics_process(true)
	animation.play("idle")

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(character):
		return
	velocity = (character.position - position).normalized() * 60.0
	move_and_slide()
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider.is_in_group("player"):
			if not collider.is_invincible and not collider.is_blocking:
				collider.take_hit_raw(10.0)
			queue_free()

func take_damage(_combat_data: CombatData, _hitbox: Hitbox) -> void:
	queue_free()
