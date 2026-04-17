extends CharacterBody2D

const Stagger_effect_scene = preload("res://stagger_effect.tscn")
const Hit_effect_scene = preload("res://hit_effect.tscn")
const Phase_two_effect_scene = preload("res://phase_two_effect.tscn")
const BOSS_ID = "grim_reaper"


@export var stats: Stats
@export var posture_regen_delay: float = 2.0
@export var posture_regen_speed: float = 20.0

@onready var character = get_tree().get_first_node_in_group("player")
@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var state_machine = $FiniteStateMachine
@onready var texture_progress_bar: TextureProgressBar = $UI/TextureProgressBar
@onready var texture_posture_bar: TextureProgressBar = $UI/TexturePostureBar



var direction : Vector2
var posture_regen_timer: float = 0.0
var can_regen: bool = false
var phase_two: bool = false

signal boss_defeated(boss_id: String)


func _ready():
	stats.posture_broken.connect(_on_posture_broken)
	stats.posture_changed.connect(_on_posture_changed)
	stats.health = stats.max_health
	stats.health_changed.connect(_on_health_changed)
	stats.no_health.connect(_on_no_health)
	hurtbox.hurt.connect(take_hit)
	set_physics_process(false)

func _on_posture_broken() -> void:
	stats.posture = 0
	spawn_stagger_effect(animated_sprite.global_position)
	state_machine.change_state("Stagger")
	posture_regen_timer = 0.0

func _on_posture_changed(new_posture: float) -> void:
	texture_posture_bar.value = new_posture

func _on_health_changed(new_health: int) -> void:
	texture_progress_bar.value = new_health

func _on_no_health() -> void:
	texture_progress_bar.visible = false
	texture_posture_bar.visible = false
	state_machine.change_state("Death")
	
	GameManager.mark_boss_defeated(BOSS_ID)
	boss_defeated.emit(BOSS_ID)
	GameManager.save_to_slot()


func _process(delta):
	if stats.posture > 0:
		posture_regen_timer += delta
		if posture_regen_timer >= posture_regen_delay:
			stats.posture = (max(0, stats.posture - posture_regen_speed * delta))
	else:
		posture_regen_timer = 0.0
	
	if !is_instance_valid(character):
		return
	
	direction = character.position - position
	animated_sprite.flip_h = direction.x < 0


func _physics_process(delta):
	if direction.length() > 30:
		velocity = direction.normalized() * 60
		move_and_collide(velocity * delta)

func take_hit(other_hitbox: Hitbox) -> void:
	stats.health -= other_hitbox.damage
	stats.posture += 10
	posture_regen_timer = 0.0
	spawn_hit_effect(animated_sprite.global_position)
	
	if stats.health <= stats.max_health / 2.0 and not phase_two:
		phase_two = true
		spawn_phase_two_effect(animated_sprite.global_position)
		state_machine.change_state("PhaseTwo")


func receive_parry(posture_dmg: float) -> void:
	stats.posture += posture_dmg
	posture_regen_timer = 0.0



func spawn_hit_effect(pos: Vector2) -> void:
	var effect = Hit_effect_scene.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos

func spawn_stagger_effect(pos: Vector2) -> void:
	var effect = Stagger_effect_scene.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos

func spawn_phase_two_effect(pos: Vector2) -> void:
	var effect = Phase_two_effect_scene.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos
