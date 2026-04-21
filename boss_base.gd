class_name BossBase extends CharacterBody2D

@export var stats: Stats
@export var posture_regen_delay : float = 2.0
@export var posture_regen_speed : float = 20.0
@export var boss_id: String = "unnamed_boss"
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _state_machine = $FiniteStateMachine

signal boss_defeated(id: String)

var direction: Vector2
var _posture_regen_timer: float = 0.0
var _player: Node2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	stats.health = stats.max_health
	stats.posture_broken.connect(_on_posture_broken)
	stats.health_changed.connect(_on_health_changed)
	stats.no_health.connect(_on_no_health)
	_hurtbox.hurt.connect(_on_hurt)
	set_physics_process(false)
	_on_boss_ready()

func _on_boss_ready() -> void:
	pass

func _process(delta: float) -> void:
	_tick_posture_regen(delta)
	_update_direction()
	_on_boss_process(delta)

func _physics_process(delta: float) -> void:
	if direction.length() > 15.0:
		velocity = direction.normalized() * 60.0
		move_and_collide(velocity * delta)


func _on_boss_process(_delta: float) -> void:
	pass

func receive_parry(posture_dmg: float) -> void:
	stats.posture += posture_dmg
	_posture_regen_timer = 0.0

func _on_hurt(combat_data: CombatData, _hitbox: Hitbox) -> void:
	if not combat_data:
		stats.health -= 10
		return
	stats.health -= combat_data.damage
	stats.posture += combat_data.posture_damage
	_posture_regen_timer = 0.0
	_on_boss_hit(combat_data)

func _on_boss_hit(_combat_data: CombatData) -> void:
	pass

func _on_health_changed(new_health: int) -> void:
	var bar := get_node_or_null("UI/TextureProgressBar")
	if bar:
		bar.value = float(new_health)

func _on_posture_broken() -> void:
	stats.posture = 0.0
	_posture_regen_timer = 0.0
	_state_machine.change_state("Stagger")

func _on_no_health() -> void:
	var hp_bar := get_node_or_null("UI/TextureProgressBar")
	var posture_bar := get_node_or_null("UI/TexturePostureBar")
	if hp_bar: hp_bar.visible = false
	if posture_bar: posture_bar.visible = false
	_state_machine.change_state("Death")
	GameManager.mark_boss_defeated(boss_id)
	GameManager.save_to_slot()
	boss_defeated.emit(boss_id)

func _tick_posture_regen(delta: float) -> void:
	if stats.posture <= 0:
		_posture_regen_timer = 0.0
		return
	_posture_regen_timer += delta
	
	if _posture_regen_timer >= posture_regen_delay:
		stats.posture = maxf(0.0, stats.posture - posture_regen_speed * delta)
	
	var posture_bar := get_node_or_null("UI/TexturePostureBar")
	if posture_bar:
		posture_bar.value = stats.posture

func _update_direction() -> void:
	if not is_instance_valid(_player):
		return
	direction = _player.global_position - global_position
