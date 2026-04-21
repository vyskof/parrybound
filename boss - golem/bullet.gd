extends Area2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var player = get_tree().get_first_node_in_group("player")
@export var damage: int = 20

var acceleration: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

func _ready():
	hurtbox.hurt.connect(take_damage)

func _physics_process(delta):
	acceleration = (player.position - position).normalized() * 700
	velocity += acceleration * delta
	rotation = velocity.angle()
	velocity = velocity.limit_length(150)
	position += velocity * delta

func take_damage(_hitbox: Hitbox) -> void:
	set_physics_process(false)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_hit_raw(damage)
		queue_free()
