extends Area2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox

var _player: Node2D = null
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	hurtbox.hurt.connect(take_damage)
	hitbox.hit_landed.connect(_on_hit_landed)
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		queue_free()	
		return
	var acceleration = (_player.position - position).normalized() * 700.0
	velocity += acceleration * delta
	rotation  = velocity.angle()
	velocity  = velocity.limit_length(150.0)
	position += velocity * delta

func take_damage(_combat_data: CombatData, _hitbox: Hitbox) -> void:
	set_physics_process(false)
	queue_free()

func _on_hit_landed(_target: Node) -> void:
	set_physics_process(false)
	queue_free()
