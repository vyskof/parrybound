extends Area2D

const LIFETIME := 5.0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox

var _player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0

func _ready() -> void:
	hurtbox.hurt.connect(take_damage)
	hitbox.hit_landed.connect(_on_hit_landed)
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	if not is_instance_valid(_player):
		queue_free()
		return
	var acceleration = (_player.global_position - global_position).normalized() * 700.0
	velocity += acceleration * delta
	rotation  = velocity.angle()
	velocity  = velocity.limit_length(150.0)
	global_position += velocity * delta

func take_damage(_combat_data: CombatData, _hitbox: Hitbox) -> void:
	set_physics_process(false)
	queue_free()

func _on_hit_landed(_target: Node) -> void:
	set_physics_process(false)
	queue_free()
