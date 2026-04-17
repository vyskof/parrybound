class_name Character extends CharacterBody2D

const  SPEED = 150.0

const DEATH_SCREEN = preload("res://deathscreen.tscn")
const PARRY_EFFECT = preload("res://parry_effect.tscn")
const PAUSE_MENU = preload("res://pause_menu.tscn")
const PERFECT_PARRY_SOUND_SEEK: float = 0.6
const GUARD_PARRY_SOUND_SEEK: float = 0.3
const PERFECT_HITSTOP_DURATION: float = 0.20
const GUARD_HITSTOP_DURATION: float = 0.08

@export var stats: Stats
@export var perfect_window_time: float = 0.08
@export var guard_window_time: float = 0.20
@export var parry_cooldown_time: float = 1.5
@export var perfect_parry_posture_damage: float = 40.0
@export var guard_parry_posture_damage: float = 15.0
@export var guard_posture_chip: float = 20.0
@export var posture_regen_delay: float = 1.5
@export var posture_regen_speed: float = 18.0
@export var guardbreak_stun_time: float = 0.6



var input_vector = Vector2.ZERO 
var last_input_vector = Vector2.DOWN

var is_parrying: bool = false
var parry_elapsed_time: float = 0.0

var is_invincible: bool = false
var posture_regen_timer: float = 0.0
var guardbreak_timer: float = 0.0
var is_guardbroken: bool = false



@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var hurtbox: Hurtbox = $Hurtbox

@onready var parrybox: Parrybox = $Parrybox
@onready var parry_window_timer: Timer = $ParryWindowTimer
@onready var parry_cooldown_timer: Timer = $ParryCooldownTimer


@onready var camera_2d: Camera2D = $Camera2D
@onready var texture_progress_bar: TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var parry_sound: AudioStreamPlayer = $ParrySound

enum ParryResult {
	NONE,
	PERFECT,
	GUARD,
	FAIL
}


func _ready() -> void:
	stats.health_changed.connect(_on_health_changed)
	stats.posture_broken.connect(_on_posture_broken)
	stats.health = stats.max_health
	GameManager.apply_save_to_player(self)
	hurtbox.hurt.connect(take_hit)
	stats.no_health.connect(die)
	parrybox.parried.connect(_on_parrybox_parried)
	parry_window_timer.timeout.connect(_on_parry_window_timeout)
	if guard_window_time < perfect_window_time:
		push_warning("guard_window_time was lower than perfect_window_time and has been clamped.")
		guard_window_time = perfect_window_time
	parry_window_timer.wait_time = max(guard_window_time, perfect_window_time)
	parry_cooldown_timer.wait_time = parry_cooldown_time
	parrybox.monitoring = false
	
	var spawn_name: String = GameManager.save_data.get("world", {}).get("spawn_point", "default")
	var spawn_node = get_tree().current_scene.find_child(spawn_name, true, false)
	if spawn_node:
		global_position = spawn_node.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		var pause_menu := PAUSE_MENU.instantiate()
		get_tree().root.add_child(pause_menu)



func _on_health_changed(new_health: int) -> void:
	texture_progress_bar.value = float(new_health)

func take_hit(other_hitbox: Hitbox) -> void:
	if is_invincible:
		return
	var parry_result := _resolve_parry_hit(other_hitbox)
	if parry_result == ParryResult.PERFECT or parry_result == ParryResult.GUARD:
		return
	stats.health -= other_hitbox.damage
	posture_regen_timer = 0.0
	_flash_red()
	_start_invincibility()

func _flash_red() -> void:
	$Sprite2D.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.15).timeout
	$Sprite2D.modulate = Color(1, 1, 1, 1)

func _start_invincibility() -> void:
	is_invincible = true                              
	await get_tree().create_timer(0.5).timeout        
	is_invincible = false                             

func die() -> void:
	hide()
	remove_from_group("player")
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	var death_screen = DEATH_SCREEN.instantiate()
	get_tree().root.add_child(death_screen)

func _physics_process(delta: float) -> void: 
	_update_guardbreak(delta)
	_update_posture_regen(delta)
	if is_parrying:
		parry_elapsed_time += delta
	
	var state = playback.get_current_node()
	match state:
		"MoveState": move_state(delta)
		"AttackState": pass
		"ParryState": parry_state(delta)

func move_state(_delta: float) -> void:
	input_vector = Input.get_vector("ui_left","ui_right", "ui_up", "ui_down") 
	if input_vector != Vector2.ZERO: 
		last_input_vector = input_vector
		var direction_vector = Vector2(input_vector.x, -input_vector.y) 
		update_blend_positions(direction_vector) 
		
	if Input.is_action_just_pressed("attack") and not is_guardbroken:
		var mouse_direction = (get_global_mouse_position() - global_position).normalized()
		var attack_direction = Vector2(mouse_direction.x, -mouse_direction.y)
		animation_tree.set("parameters/StateMachine/AttackState/blend_position", attack_direction)
		playback.travel("AttackState")
	
	if Input.is_action_just_pressed("parry"):
		start_parry()
	
	velocity = input_vector * SPEED 
	move_and_slide() 

func start_parry() -> void:
	
	if not parry_cooldown_timer.is_stopped():
		return
	if is_parrying:
		return
	if is_guardbroken:
		return
	
	is_parrying = true
	parry_elapsed_time = 0.0
	parrybox.monitoring = true
	parry_window_timer.start(max(guard_window_time, perfect_window_time))
	playback.travel("ParryState")


func _on_parrybox_parried(hitbox: Area2D) -> void:
	if hitbox is Hitbox:
		_resolve_parry_hit(hitbox as Hitbox)

func _on_parry_window_timeout() -> void:
	_stop_parry()


func parry_state(_delta: float) -> void:
	move_and_slide()

func _resolve_parry_hit(hitbox: Hitbox) -> ParryResult:
	if not is_parrying:
		return ParryResult.NONE
	
	var elapsed = parry_elapsed_time
	if elapsed <= perfect_window_time:
		_apply_parry_result(hitbox, perfect_parry_posture_damage, true)
		return ParryResult.PERFECT
	if elapsed <= guard_window_time:
		stats.posture += guard_posture_chip
		posture_regen_timer = 0.0
		_apply_parry_result(hitbox, guard_parry_posture_damage, false)
		return ParryResult.GUARD
	
	_stop_parry()
	return ParryResult.FAIL

func _apply_parry_result(hitbox: Hitbox, posture_damage: float, is_perfect: bool) -> void:
	_stop_parry()
	hitbox.register_hit(hurtbox)
	var source := hitbox.owner
	if is_instance_valid(source) and source.has_method("receive_parry"):
		source.receive_parry(posture_damage)
	spawn_parry_effect(hurtbox.global_position)
	parry_sound.play(PERFECT_PARRY_SOUND_SEEK if is_perfect else GUARD_PARRY_SOUND_SEEK)
	if is_perfect:
		camera_2d.shake()
	_hitstop(PERFECT_HITSTOP_DURATION if is_perfect else GUARD_HITSTOP_DURATION)

func _stop_parry() -> void:
	if is_parrying:
		parry_cooldown_timer.start()
	is_parrying = false
	parry_elapsed_time = 0.0
	parry_window_timer.stop()
	parrybox.set_deferred("monitoring", false)
	playback.travel("MoveState")

func _hitstop(duration: float) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_posture_broken() -> void:
	stats.posture = 0
	posture_regen_timer = 0.0
	guardbreak_timer = guardbreak_stun_time
	is_guardbroken = true
	_stop_parry()

func _update_guardbreak(delta: float) -> void:
	if guardbreak_timer > 0.0:
		guardbreak_timer = max(0.0, guardbreak_timer - delta)
	is_guardbroken = guardbreak_timer > 0.0

func _update_posture_regen(delta: float) -> void:
	if stats.posture <= 0:
		posture_regen_timer = 0.0
		return
	if is_parrying:
		posture_regen_timer = 0.0
		return
	posture_regen_timer += delta
	if posture_regen_timer >= posture_regen_delay:
		stats.posture = max(0.0, stats.posture - posture_regen_speed * delta)

func spawn_parry_effect(pos: Vector2) -> void:
	var effect = PARRY_EFFECT.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos

func update_blend_positions(direction_vector: Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/AttackState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/ParryState/blend_position", direction_vector)
