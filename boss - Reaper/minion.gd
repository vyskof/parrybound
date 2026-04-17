extends CharacterBody2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var character = get_tree().get_first_node_in_group("player")
@onready var animation = $AnimatedSprite2D

func _ready():
	hurtbox.hurt.connect(take_damage)
	set_physics_process(false)
	await animation.animation_finished
	set_physics_process(true)
	animation.play("idle")

func _physics_process(_delta):
	if !is_instance_valid(character):
		return
	var direction = character.position - position
	velocity = direction.normalized() * 60
	move_and_slide()
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider.is_in_group("player"):
			if not collider.is_invincible:
				collider.stats.health -= 10
				collider._flash_red()
				collider._start_invincibility()
			queue_free()

func take_damage(_hitbox: Hitbox) -> void:
	queue_free()
