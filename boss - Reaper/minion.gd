extends CharacterBody2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var character = get_tree().get_first_node_in_group("player")
@onready var animation = $AnimatedSprite2D

func _ready() -> void:
	hurtbox.hurt.connect(take_damage)
	hitbox.hit_landed.connect(_on_hit_landed)
	set_physics_process(false)
	await animation.animation_finished
	set_physics_process(true)
	animation.play("idle")

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(character):
		return
	velocity = (character.position - position).normalized() * 60.0
	move_and_slide()

func take_damage(_combat_data: CombatData, _hitbox: Hitbox) -> void:
	queue_free()

func _on_hit_landed(_target: Node) -> void:
	queue_free()
