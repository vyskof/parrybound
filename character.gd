class_name Character extends CharacterBody2D

const  SPEED = 150.0

const DEATH_SCREEN = preload("res://deathscreen.tscn")
const PAUSE_MENU = preload("res://pause_menu.tscn")

const posture_regen_rate := 15.0

@export var stats: Stats
@export var parry_cooldown_time: float = 0.6


var input_vector = Vector2.ZERO 
var last_input_vector = Vector2.DOWN
var is_invincible: bool = false



@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _playback := _animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _parrybox: Parrybox = $Parrybox
@onready var _parry_cooldown_timer: Timer = $ParryCooldownTimer
@onready var _health_bar : TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var _sprite : Sprite2D = $Sprite2D
@onready var _parry_resolver: ParryResolver = $ParryResolver
@onready var _feedback: FeedbackOrchestrator = $FeedbackOrchestrator



func _ready() -> void:
	stats.health_changed.connect(_on_stats_health_changed)
	stats.health = stats.max_health
	GameManager.apply_save_to_player(self)
	_hurtbox.hurt.connect(_on_hurtbox_hurt)
	_parrybox.parried.connect(_on_parrybox_parried)
	_parry_cooldown_timer.wait_time = parry_cooldown_time
	_parry_resolver.resolved.connect(_on_parry_resolver_resolved)
	stats.no_health.connect(_on_stats_no_health)
	stats.posture_broken.connect(_on_stats_posture_broken)
	_parrybox.monitoring = false



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		get_tree().root.add_child(PAUSE_MENU.instantiate())

func _flash_red() -> void:
	_sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
	await get_tree().create_timer(0.15, true, false, true).timeout
	_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _start_invincibility(duration: float) -> void:
	is_invincible = true                              
	await get_tree().create_timer(duration, true, false, true).timeout       
	is_invincible = false                             
	
func _die() -> void:
	hide()
	remove_from_group("player")
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	get_tree().root.add_child(DEATH_SCREEN.instantiate())

func _physics_process(delta: float) -> void: 
	_parry_resolver.tick(delta)
	_tick_posture_regen(delta)
	
	match _playback.get_current_node():
		"MoveState": _process_move_state(delta)
		"AttackState": pass
		"ParryState": move_and_slide()

func _process_move_state(_delta: float) -> void:
	input_vector = Input.get_vector("ui_left","ui_right", "ui_up", "ui_down") 
	
	if input_vector != Vector2.ZERO: 
		last_input_vector = input_vector
		var anim_dir := Vector2(input_vector.x, -input_vector.y) 
		_update_all_blend_positions(anim_dir) 
		
	if Input.is_action_just_pressed("attack"):
		_start_attack()
	
	if Input.is_action_just_pressed("parry"):
		_try_start_parry()
	
	velocity = input_vector * SPEED 
	move_and_slide() 

func _start_attack() -> void:
	var mouse_dir   := (get_global_mouse_position() - global_position).normalized()
	var attack_dir  := Vector2(mouse_dir.x, -mouse_dir.y)
	_animation_tree.set("parameters/StateMachine/AttackState/blend_position",attack_dir)
	_playback.travel("AttackState")


func _try_start_parry() -> void:
	
	if not _parry_cooldown_timer.is_stopped():
		return
	if _parry_resolver.is_active():
		return
	if _parry_resolver.is_in_cooldown():
		return
	
	_parry_resolver.try_start()
	_parrybox.monitoring = true
	_playback.travel("ParryState")

func _on_hurtbox_hurt(combat_data: CombatData, hitbox: Hitbox) -> void:
	if is_invincible:
		return
	var result := _parry_resolver.evaluate(combat_data)
	match result:
		ParryResolver.Result.NONE:
			if combat_data:
				stats.health  -= combat_data.damage
				stats.posture += combat_data.posture_damage
				if hitbox and combat_data.knockback_force > 0.0:
					_apply_knockback(hitbox, combat_data)
			_feedback.play_hit_feedback(global_position)
			_flash_red()
			_start_invincibility(0.5)
		
		ParryResolver.Result.GUARD:
			if combat_data:
				stats.posture += combat_data.guard_chip
		ParryResolver.Result.PERFECT:
			pass
		ParryResolver.Result.WHIFF:
			pass


func _on_parry_resolver_resolved(result: ParryResolver.Result,_combat_data: CombatData) -> void:
	_parrybox.set_deferred("monitoring", false)
	if result == ParryResolver.Result.WHIFF:
		_parry_cooldown_timer.start()
	_playback.travel("MoveState")
	_feedback.play_parry_feedback(result, global_position)


func _on_parrybox_parried(hitbox: Area2D) -> void:
	if not hitbox.owner.has_method("receive_parry"):
		return
	if not hitbox is Hitbox:
		return
	var typed_hitbox := hitbox as Hitbox
	var is_perfect := (_parry_resolver._timer <= _parry_resolver.base_perfect_window and not _parry_resolver.is_in_cooldown())
	var posture_dmg := 0.0
	if typed_hitbox.combat_data:
		posture_dmg = (typed_hitbox.combat_data.parry_posture_reward if is_perfect else typed_hitbox.combat_data.guard_posture_reward)
	else:
		posture_dmg = 35.0 if is_perfect else 12.0
	hitbox.owner.receive_parry(posture_dmg)
	var result := (ParryResolver.Result.PERFECT if is_perfect else ParryResolver.Result.GUARD)
	_feedback.play_boss_parried_feedback(result, hitbox.owner.global_position)

func _on_stats_health_changed(new_health: int) -> void:
	_health_bar.value = float(new_health)

func _on_stats_no_health() -> void:
	_die()

func _on_stats_posture_broken() -> void:
	stats.posture = 0.0
	_feedback.play_stagger_feedback(global_position)
	_start_invincibility(1.5)
	_playback.travel("MoveState")

func _tick_posture_regen(delta: float) -> void:
	if stats.posture > 0 and not _parry_resolver.is_active():
		stats.posture = maxf(0.0, stats.posture - posture_regen_rate * delta)

func _apply_knockback(hitbox: Hitbox, combat_data: CombatData) -> void:
	var direction : Vector2
	if combat_data.knockback_direction_override != Vector2.ZERO:
		direction = combat_data.knockback_direction_override.normalized()
	else:
		direction = (global_position - hitbox.owner.global_position).normalized()
	velocity += direction * combat_data.knockback_force



func _update_all_blend_positions(direction: Vector2) -> void:
	for param_path in ["parameters/StateMachine/MoveState/IdleState/blend_position","parameters/StateMachine/MoveState/RunState/blend_position","parameters/StateMachine/AttackState/blend_position","parameters/StateMachine/ParryState/blend_position",]:
		_animation_tree.set(param_path, direction)
