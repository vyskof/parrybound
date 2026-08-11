extends Area2D

@onready var hurtbox: Hurtbox = $Hurtbox
@export var damage: float = 20

var _player: Node2D = null
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	hurtbox.hurt.connect(take_damage)
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

func _on_parried(_combat_data: CombatData, _hitbox: Hitbox) -> void:
	set_physics_process(false)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	_deal_damage_to_player(body)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		_deal_damage_to_player(area.get_parent())

func _deal_damage_to_player(target: Node) -> void:
	if not is_instance_valid(target) or not target.is_in_group("player"):
		return
	if target.has_method("take_hit_raw"):
		target.take_hit_raw(damage)
	set_physics_process(false)
	queue_free()
