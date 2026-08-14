class_name Character extends CharacterBody2D

const SPEED                := 150.0
const SPEED_GUARD          := 80.0
const POSTURE_REGEN_RATE   := 15.0
const POSTURE_REGEN_DELAY  := 2.5
const STAGGER_DURATION     := 1.8
const PARRY_POSTURE_RESTORE:= 8.0

const KNOCKBACK_FRICTION   := 400.0

const DEFLECT_PUSHBACK     := 90.0
const BLOCK_PUSHBACK       := 45.0

const DEFLECT_STAMINA_REWARD := 12.0

const DODGE_SPEED          := 300.0   
const DODGE_DURATION       := 0.18    
const DODGE_IFRAMES        := 0.14    
const DODGE_STAMINA_COST   := 25.0    
const STAMINA_REGEN_RATE   := 40.0    
const STAMINA_REGEN_DELAY  := 1.0     
const DODGE_COOLDOWN       := 0.25

const MICRO_DODGE_DISTANCE     := 25.0
const MICRO_DODGE_DURATION     := 0.10
const MICRO_DODGE_STAMINA_COST := 8.0
const MICRO_DODGE_COOLDOWN     := 0.5

const DODGE_CANCEL_STAMINA_MULT := 1.3

const ATTACK_STAMINA_COST      := 15.0

const REGAIN_RATIO             := 0.5    
const REGAIN_DECAY_DELAY       := 1.0    
const REGAIN_DECAY_RATE        := 15.0   
const POSTURE_RECOVERY_ON_HIT  := 4.0    

const COUNTER_WINDOW_DURATION  := 0.30
const COUNTER_POSTURE_MULT     := 1.5
const BASE_ATTACK_POSTURE_DMG  := 10.0

const JUST_FRAME_STAMINA_BONUS  := 8.0
const JUST_FRAME_POSTURE_MULT   := 2.2   
const JUST_FRAME_WINDOW_BONUS   := 0.15 

const STREAK_RESET_TIME         := 2.5    
const STREAK_MAX                := 4      
const STREAK_POSTURE_PER_LEVEL  := 0.15   
const STREAK_PITCH_PER_LEVEL    := 0.10

const COMBO_PULSE_WINDOW   := 0.15
const COMBO_ATTACK_SPEED   := 1.15

const RIPOSTE_ATTACK_SPEED   := 1.4
const RIPOSTE_LUNGE_DISTANCE := 14.0

const LOW_HEALTH_RATIO    := 0.20
const FOOTSTEP_INTERVAL   := 0.34

const TINNITUS_THRESHOLD_RATIO := 0.3
const TINNITUS_DURATION        := 2.2

const AFTERIMAGE_INTERVAL := 0.05
const AFTERIMAGE_SCENE    := preload("res://effects/dodge_afterimage.tscn")

const ATTACK_TRAIL_TINT     := Color(1.0, 0.95, 0.75, 0.55)
const ATTACK_TRAIL_INTERVAL := 0.05
const ATTACK_TRAIL_FADE     := 0.16

const SCENE_DEATH := preload("res://ui/deathscreen.tscn")
const SCENE_PAUSE := preload("res://ui/pause_menu.tscn")

@export var stats: Stats
@export var footstep_sounds: Array[AudioStreamPlayer2D] = []

var input_vector      := Vector2.ZERO
var last_input_vector := Vector2.DOWN
var is_invincible     := false

var _is_dodging        := false
var _dodge_direction   := Vector2.ZERO
var _stamina_regen_timer : float = 0.0
var _dodge_cooldown_timer : float = 0.0

var _is_micro_dodging: bool = false
var _micro_dodge_direction: Vector2 = Vector2.ZERO
var _micro_dodge_timer: float = 0.0
var _micro_dodge_cooldown_timer: float = 0.0

var _stamina_blink_tween: Tween = null

var _footstep_timer: float = 0.0
var _tinnitus_active: bool = false

var is_blocking: bool:
	get: return _parry_resolver != null and _parry_resolver.is_blocking()

var is_parrying: bool:
	get: return _in_parry_state

var _knockback_velocity := Vector2.ZERO
var _knockback_lock     : float = 0.0
var _in_parry_state     := false
var _in_attack_state    := false

var _deflect_streak     : int   = 0
var _streak_reset_timer : float = 0.0

var _posture_regen_timer: float = 0.0
var _is_staggered       : bool  = false
var _stagger_timer      : float = 0.0

var _combo_pulse_timer  : float = 0.0
var _regain_pool: float = 0.0
var _regain_decay_timer: float = 0.0
var _attack_buffered    : bool  = false
var _was_in_attack      : bool  = false
var _parry_buffered     : bool = false
var _dodge_buffered     : bool = false

var _attack_just_started: bool = false
var _attack_sequence_id: int = 0
var _low_health_active: bool = false

var _is_intro_locked: bool = false

var _in_counter_window  : bool  = false
var _counter_timer      : float = 0.0

@onready var _animation_player : AnimationPlayer      = $AnimationPlayer
@onready var _animation_tree   : AnimationTree        = $AnimationTree
@onready var _hurtbox          : Hurtbox              = $Hurtbox
@onready var _parrybox         : Parrybox             = $Parrybox
@onready var _health_bar       : TextureProgressBar   = $CanvasLayer/TextureProgressBar
@onready var _posture_bar      : TextureProgressBar   = $CanvasLayer/TexturePostureBar
@onready var _stamina_bar      : TextureProgressBar   = $CanvasLayer/TextureStaminaBar
@onready var _sprite           : Sprite2D             = $Sprite2D
@onready var _parry_resolver   : ParryResolver        = $ParryResolver
@onready var _feedback         : FeedbackOrchestrator = $FeedbackOrchestrator
@onready var _parry_cooldown   : Timer                = $ParryCooldownTimer
@onready var _hitbox           : Hitbox               = $Hitbox
@onready var _parry_sound      : AudioStreamPlayer    = $ParrySound
@onready var _regain_bar       : TextureProgressBar   = $CanvasLayer/RegainBar
@onready var _footstep_player  : AudioStreamPlayer2D  = $FootstepSound
@onready var _heartbeat_player : AudioStreamPlayer    = $HeartbeatSound
@onready var _breath_player    : AudioStreamPlayer    = $BreathSound
@onready var _tinnitus_player  : AudioStreamPlayer    = $TinnitusSound


var _playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	_playback = _animation_tree.get("parameters/StateMachine/playback")

	_make_parry_animations_loop()

	stats.health  = stats.max_health
	stats.posture = 0.0
	stats.stamina  = stats.max_stamina    
	_stamina_regen_timer = 0.0

	_health_bar.max_value  = stats.max_health
	_posture_bar.max_value = float(stats.max_posture)
	_posture_bar.value     = 0.0
	
	_regain_bar.max_value = stats.max_health
	_regain_bar.value     = stats.health

	_stamina_bar.max_value = stats.max_stamina
	_stamina_bar.value     = stats.max_stamina
	stats.stamina_changed.connect(_on_stamina_changed)

	stats.health_changed.connect(_on_health_changed)
	stats.posture_changed.connect(_on_posture_changed)
	stats.no_health.connect(_on_no_health)
	stats.posture_broken.connect(_on_posture_broken)

	_hurtbox.hurt.connect(_on_hurt)
	_hitbox.hit_landed.connect(_on_own_hitbox_landed)
	_parrybox.parried.connect(_on_parrybox_parried)
	_parrybox.monitoring = false

	GameManager.apply_save_to_player(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		get_tree().root.add_child(SCENE_PAUSE.instantiate())

# ─── Main loop ────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _is_intro_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_parry_resolver.tick(delta)
	_tick_posture_regen(delta)
	_tick_knockback(delta)
	_tick_stagger(delta)
	_tick_stamina_regen(delta)
	_tick_dodge_cooldown(delta)
	_tick_micro_dodge_cooldown(delta)
	_tick_combo_pulse(delta)
	_tick_counter_window(delta)
	_tick_streak_reset(delta)
	_tick_regain(delta)

	if _was_in_attack and not _attack_just_started and _playback.get_current_node() == "MoveState":
		_in_attack_state = false
		_animation_tree.set("parameters/TimeScale/scale", 1.0)
		_combo_pulse_timer = COMBO_PULSE_WINDOW
		if _parry_buffered:
			_parry_buffered = false
			_attack_buffered = false
			_enter_parry()
		elif _dodge_buffered:
			_dodge_buffered  = false
			_attack_buffered = false
			_parry_buffered  = false
			_clear_hitbox()
			_enter_dodge()
		elif _attack_buffered:
			_attack_buffered = false
			_enter_attack()
	_attack_just_started = false
	_was_in_attack = _in_attack_state


	if _is_micro_dodging:
		_micro_dodge_timer -= delta
		velocity = _micro_dodge_direction * (MICRO_DODGE_DISTANCE / MICRO_DODGE_DURATION) + _knockback_velocity
		move_and_slide()
		if _micro_dodge_timer <= 0.0:
			_is_micro_dodging = false
		return


	if _is_dodging:
		velocity = _dodge_direction * DODGE_SPEED + _knockback_velocity
		move_and_slide()
		return


	if _knockback_lock > 0.0:
		_knockback_lock -= delta
		velocity = _knockback_velocity
		move_and_slide()
		return

	if _is_staggered:
		velocity = _knockback_velocity
		move_and_slide()
		return

	if _in_parry_state:
		_process_parry()
	elif _in_attack_state:
		_process_attack()
	else:
		_process_move(delta)

func _process_move(_delta: float) -> void:
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		_update_blend_positions(Vector2(input_vector.x, -input_vector.y))

	if Input.is_action_just_pressed("attack"):
		_enter_attack()
		return

	if Input.is_action_just_pressed("parry"):
		_enter_parry()
		return

	if Input.is_action_just_pressed("dodge"):
		_enter_dodge()
		return

	velocity = input_vector * SPEED + _knockback_velocity
	move_and_slide()
	_tick_footsteps(_delta, input_vector.length())


func _process_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		if not _attack_buffered and stats.stamina >= ATTACK_STAMINA_COST:
			_attack_buffered = true
	if Input.is_action_just_pressed("parry"):
		_parry_buffered = true 
	
	if Input.is_action_just_pressed("dodge"):
		var cancel_cost := DODGE_STAMINA_COST * DODGE_CANCEL_STAMINA_MULT
		if stats.stamina >= cancel_cost and _dodge_cooldown_timer <= 0.0:
			_attack_buffered  = false
			_parry_buffered   = false
			_in_attack_state  = false
			_animation_tree.set("parameters/TimeScale/scale", 1.0)
			_playback.start("MoveState", true)
			_clear_hitbox()
			_enter_dodge()
			return
		else:
			_dodge_buffered = true
	
	velocity = _knockback_velocity
	move_and_slide()



func _process_parry() -> void:
	_parrybox.monitoring = _parry_resolver.is_deflect_active()

	if Input.is_action_just_pressed("dodge") and _try_micro_dodge():
		return

	if Input.is_action_pressed("parry"):
		_parry_resolver.start_block()
	else:
		_exit_parry()
		return

	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		_update_blend_positions(Vector2(input_vector.x, -input_vector.y))

	velocity = input_vector * SPEED_GUARD + _knockback_velocity
	move_and_slide()
	_tick_footsteps(get_physics_process_delta_time(), input_vector.length() * 0.6)

func _enter_attack() -> void:
	if _in_attack_state:
		return
	if stats.stamina < ATTACK_STAMINA_COST:
		return
	_in_attack_state = true
	_attack_just_started = true
	stats.stamina -= ATTACK_STAMINA_COST
	_stamina_regen_timer = 0.0
	_attack_buffered = false

	var is_riposte := _in_counter_window
	var speed := RIPOSTE_ATTACK_SPEED if is_riposte else (COMBO_ATTACK_SPEED if _combo_pulse_timer > 0.0 else 1.0)
	_animation_tree.set("parameters/TimeScale/scale", speed)

	var mouse_dir := (get_global_mouse_position() - global_position).normalized()
	_animation_tree.set(
		"parameters/StateMachine/AttackState/blend_position",
		Vector2(mouse_dir.x, -mouse_dir.y)
	)
	_playback.travel("AttackState")

	if is_riposte:
		_play_riposte_lunge(mouse_dir)
	
	_attack_sequence_id += 1
	_spawn_attack_trail(_attack_sequence_id)

func _play_riposte_lunge(dir: Vector2) -> void:
	var target := global_position + dir * RIPOSTE_LUNGE_DISTANCE
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var flash := create_tween()
	flash.tween_property(_sprite, "modulate", Color(1.4, 1.4, 1.0, 1.0), 0.05)
	flash.tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _enter_parry() -> void:
	if not _parry_cooldown.is_stopped():
		return
	_parry_cooldown.start(0.3) 
	_in_parry_state = true
	_parrybox.monitoring = true
	_parry_resolver.try_start_deflect()
	var mouse_dir := (get_global_mouse_position() - global_position).normalized()
	_update_blend_positions(Vector2(mouse_dir.x, -mouse_dir.y))
	_playback.travel("ParryState")


func _exit_parry() -> void:
	_in_parry_state = false
	_parry_resolver.stop_block()
	_parrybox.monitoring = false
	_playback.start("MoveState", true)


func take_hit_raw(damage: float, inv_duration: float = 0.5) -> void:
	if is_invincible:
		return
	stats.health -= damage
	_add_regain_pool(damage)
	_pulse_damage_vignette(damage)
	_feedback.play_hit_feedback(global_position)
	if not _is_staggered:
		_flash_red()
	_start_invincibility(inv_duration)


func _on_hurt(combat_data: CombatData, hitbox: Hitbox) -> void:
	if is_invincible:
		return

	var result := _parry_resolver.evaluate(combat_data)

	match result:
		ParryResolver.Result.DEFLECT:
			_deflect_streak     = mini(_deflect_streak + 1, STREAK_MAX)
			_streak_reset_timer = 0.0
			
			var is_just_frame  := _parry_resolver.was_just_frame()
			var posture_mult   := _get_streak_posture_mult()
			var counter_dur    := COUNTER_WINDOW_DURATION
			
			if is_just_frame:
				posture_mult  = maxf(posture_mult, JUST_FRAME_POSTURE_MULT)
				counter_dur  += JUST_FRAME_WINDOW_BONUS
				stats.stamina += DEFLECT_STAMINA_REWARD + JUST_FRAME_STAMINA_BONUS
			else:
				stats.stamina += DEFLECT_STAMINA_REWARD
				
			stats.posture = maxf(0.0, stats.posture - PARRY_POSTURE_RESTORE)
			_posture_regen_timer = 0.0
			_in_counter_window = true
			_counter_timer     = counter_dur
			_hitbox.combat_data.posture_damage = BASE_ATTACK_POSTURE_DMG * posture_mult
			
			_parry_sound.pitch_scale = 1.0 + (_deflect_streak - 1) * STREAK_PITCH_PER_LEVEL
			
			
			_feedback.play_parry_feedback(ParryResolver.Result.DEFLECT, global_position, combat_data, _deflect_streak, is_just_frame)
			_apply_parry_pushback(hitbox, DEFLECT_PUSHBACK)

		ParryResolver.Result.BLOCK:
			if combat_data:
				stats.posture += combat_data.guard_chip
			_posture_regen_timer = 0.0
			_feedback.play_parry_feedback(ParryResolver.Result.BLOCK, global_position, combat_data)
			_apply_parry_pushback(hitbox, BLOCK_PUSHBACK)
			_flash_posture_bar()

		ParryResolver.Result.NONE:
			var dmg  := combat_data.damage          if combat_data else (hitbox.damage if hitbox else 10.0)
			var pdmg := combat_data.posture_damage   if combat_data else 5.0
			stats.health  -= dmg
			_add_regain_pool(dmg)
			_pulse_damage_vignette(dmg)
			stats.posture += pdmg
			_posture_regen_timer = 0.0
			if hitbox and combat_data and combat_data.knockback_force > 0.0:
				_apply_knockback(hitbox, combat_data)
			var attacker_pos = hitbox.owner.global_position if hitbox and is_instance_valid(hitbox.owner) else Vector2.ZERO
			_feedback.play_hit_feedback(global_position, combat_data, attacker_pos)
			if not _is_staggered:
				_flash_red()
			_start_invincibility(0.5)


func _on_parrybox_parried(hitbox: Area2D) -> void:
	if not hitbox is Hitbox:
		return
	if not hitbox.owner.has_method("receive_parry"):
		return
	var typed  := hitbox as Hitbox
	var reward := typed.combat_data.parry_posture_reward if typed.combat_data else 35.0
	hitbox.owner.receive_parry(reward)


func _apply_knockback(hitbox: Hitbox, data: CombatData) -> void:
	var dir: Vector2
	if data.knockback_direction_override != Vector2.ZERO:
		dir = data.knockback_direction_override.normalized()
	else:
		dir = (global_position - hitbox.owner.global_position).normalized()
	_knockback_velocity = dir * data.knockback_force
	_knockback_lock = 0.2

func _apply_parry_pushback(hitbox: Hitbox, force: float) -> void:
	var push_dir = (global_position - hitbox.owner.global_position).normalized()
	_knockback_velocity = push_dir * force

func _tick_knockback(delta: float) -> void:
	if _knockback_velocity.length_squared() < 1.0:
		_knockback_velocity = Vector2.ZERO
		return
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)

func _tick_stagger(delta: float) -> void:
	if not _is_staggered:
		return
	_stagger_timer -= delta
	if _stagger_timer <= 0.0:
		_is_staggered = false
		_sprite.modulate = Color.WHITE


func _tick_posture_regen(delta: float) -> void:
	if stats.posture <= 0.0 or _is_staggered:
		_posture_regen_timer = 0.0
		return
	if is_blocking:
		return
	_posture_regen_timer += delta
	if _posture_regen_timer >= POSTURE_REGEN_DELAY:
		stats.posture = maxf(0.0, stats.posture - POSTURE_REGEN_RATE * delta)

func _tick_stamina_regen(delta: float) -> void:
	if stats.stamina >= stats.max_stamina:
		return
	_stamina_regen_timer += delta
	if _stamina_regen_timer >= STAMINA_REGEN_DELAY:
		stats.stamina += STAMINA_REGEN_RATE * delta

func _tick_combo_pulse(delta: float) -> void:
	if _combo_pulse_timer > 0.0:
		_combo_pulse_timer -= delta

func _tick_counter_window(delta: float) -> void:
	if not _in_counter_window:
		return
	_counter_timer -= delta
	if _counter_timer <= 0.0:
		_in_counter_window = false
		_counter_timer     = 0.0
		_hitbox.combat_data.posture_damage = BASE_ATTACK_POSTURE_DMG

func _tick_footsteps(delta: float, moving_ratio: float) -> void:
	if moving_ratio <= 0.05 or footstep_sounds.is_empty():
		_footstep_timer = 0.0
		return

	_footstep_timer -= delta * moving_ratio
	if _footstep_timer <= 0.0:
		_footstep_timer = FOOTSTEP_INTERVAL
		var selected_player = footstep_sounds.pick_random()
		if selected_player and selected_player.stream:
			_footstep_player.stream = selected_player.stream
			_footstep_player.pitch_scale = randf_range(0.92, 1.08)
			_footstep_player.play()

func _tick_streak_reset(delta: float) -> void:
	if _deflect_streak == 0:
		return
	_streak_reset_timer += delta
	if _streak_reset_timer >= STREAK_RESET_TIME:
		_deflect_streak     = 0
		_streak_reset_timer = 0.0
		_parry_sound.pitch_scale = 1.0



func _on_stamina_changed(new_stamina: float) -> void:
	_stamina_bar.value = new_stamina
	if new_stamina <= stats.max_stamina * 0.20:
		_start_stamina_blink()
		if _breath_player and not _breath_player.playing:
			_breath_player.play()
	else:
		_stop_stamina_blink()
		if _breath_player and _breath_player.playing:
			_breath_player.stop()

func _start_stamina_blink() -> void:
	if _stamina_blink_tween and _stamina_blink_tween.is_running():
		return
	_stamina_blink_tween = create_tween().set_loops()
	_stamina_blink_tween.tween_property(_stamina_bar, "modulate:a", 0.2, 0.2)
	_stamina_blink_tween.tween_property(_stamina_bar, "modulate:a", 1.0, 0.2)

func _stop_stamina_blink() -> void:
	if _stamina_blink_tween:
		_stamina_blink_tween.kill()
		_stamina_blink_tween = null
	_stamina_bar.modulate.a = 1.0


func _enter_dodge() -> void:
	if _is_dodging:
		return
	if _dodge_cooldown_timer > 0.0:
		return
	if stats.stamina < DODGE_STAMINA_COST:
		return
	stats.stamina -= DODGE_STAMINA_COST
	_stamina_regen_timer = 0.0
	_is_dodging = true
	_dodge_direction = input_vector if input_vector != Vector2.ZERO else -last_input_vector
	_start_invincibility(DODGE_IFRAMES)
	_sprite.modulate.a = 0.5
	
	var elapsed := 0.0
	while elapsed < DODGE_DURATION:
		_spawn_afterimage()
		await get_tree().create_timer(AFTERIMAGE_INTERVAL, true, false, true).timeout
		elapsed += AFTERIMAGE_INTERVAL
	
	_is_dodging = false
	_dodge_cooldown_timer = DODGE_COOLDOWN
	_sprite.modulate.a = 1.0

func _tick_dodge_cooldown(delta: float) -> void:
	if _dodge_cooldown_timer > 0.0:
		_dodge_cooldown_timer -= delta

func _try_micro_dodge() -> bool:
	if _is_micro_dodging or _micro_dodge_cooldown_timer > 0.0:
		return false
	if stats.stamina < MICRO_DODGE_STAMINA_COST:
		return false

	stats.stamina -= MICRO_DODGE_STAMINA_COST
	_stamina_regen_timer = 0.0
	_micro_dodge_direction = input_vector if input_vector != Vector2.ZERO else -last_input_vector
	_micro_dodge_timer = MICRO_DODGE_DURATION
	_micro_dodge_cooldown_timer = MICRO_DODGE_COOLDOWN
	_is_micro_dodging = true
	return true

func _tick_micro_dodge_cooldown(delta: float) -> void:
	if _micro_dodge_cooldown_timer > 0.0:
		_micro_dodge_cooldown_timer -= delta



func _make_parry_animations_loop() -> void:
	var lib := _animation_player.get_animation_library("")
	for anim_name: String in ["parry_down", "parry_left", "parry_right", "parry_up"]:
		if lib.has_animation(anim_name):
			lib.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR

func _spawn_afterimage(tint: Color = Color(0.6, 0.8, 1.0, 0.5), fade_duration: float = 0.1) -> void:
	var afterimage := AFTERIMAGE_SCENE.instantiate()
	afterimage.init(_sprite, tint, fade_duration)
	get_parent().add_child(afterimage)

func _spawn_attack_trail(sequence_id: int) -> void:
	while _in_attack_state and _attack_sequence_id == sequence_id:
		_spawn_afterimage(ATTACK_TRAIL_TINT, ATTACK_TRAIL_FADE)
		await get_tree().create_timer(ATTACK_TRAIL_INTERVAL, true, false, true).timeout


func _update_blend_positions(dir: Vector2) -> void:
	for path: String in [
		"parameters/StateMachine/MoveState/IdleState/blend_position",
		"parameters/StateMachine/MoveState/RunState/blend_position",
		"parameters/StateMachine/AttackState/blend_position",
		"parameters/StateMachine/ParryState/blend_position",
	]:
		_animation_tree.set(path, dir)

func _flash_red() -> void:
	_sprite.modulate = Color(1.0, 0.3, 0.3)
	await get_tree().create_timer(0.15, true, false, true).timeout
	if not _is_staggered:
		_sprite.modulate = Color.WHITE

var _invincibility_count: int = 0

func _start_invincibility(duration: float) -> void:
	is_invincible = true
	_invincibility_count += 1
	await get_tree().create_timer(duration, true, false, true).timeout
	_invincibility_count -= 1
	if _invincibility_count <=0:
		_invincibility_count = 0
		is_invincible = false

func _on_health_changed(new_health: float) -> void:
	_health_bar.value = new_health
	_update_regain_bar()
	_update_low_health_vignette(new_health)


func _on_posture_changed(new_posture: float) -> void:
	_posture_bar.value = new_posture


func _on_no_health() -> void:
	DamageVignette.stop_low_health_pulse()
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	hide()
	remove_from_group("player")
	get_tree().root.add_child(SCENE_DEATH.instantiate())


func _pulse_damage_vignette(damage_amount: float) -> void:
	var ratio := clampf(damage_amount / stats.max_health, 0.0, 1.0)
	var intensity := clampf(0.15 + ratio * 1.2, 0.15, 0.85)
	DamageVignette.pulse(intensity)
	if ratio >= TINNITUS_THRESHOLD_RATIO:
		_play_tinnitus()

func _play_tinnitus() -> void:
	if _tinnitus_active or not _tinnitus_player.stream:
		return
	_tinnitus_active = true

	var master_bus := AudioServer.get_bus_index("Master")
	var filter := AudioEffectLowPassFilter.new()
	filter.cutoff_hz = 700.0
	AudioServer.add_bus_effect(master_bus, filter)
	var effect_index := AudioServer.get_bus_effect_count(master_bus) - 1

	_tinnitus_player.play()

	var tween := create_tween()
	tween.tween_method(
		func(hz: float): filter.cutoff_hz = hz,
		700.0, 20000.0, TINNITUS_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	AudioServer.remove_bus_effect(master_bus, effect_index)
	_tinnitus_active = false	



func _update_low_health_vignette(new_health: float) -> void:
	var is_low := new_health > 0.0 and new_health <= stats.max_health * LOW_HEALTH_RATIO
	if is_low == _low_health_active:
		return
	_low_health_active = is_low
	if is_low:
		DamageVignette.start_low_health_pulse()
		if _heartbeat_player and not _heartbeat_player.playing:
			_heartbeat_player.play()
	else:
		DamageVignette.stop_low_health_pulse()
		if _heartbeat_player:
			_heartbeat_player.stop()


func _on_posture_broken() -> void:
	stats.posture        = 0.0
	_posture_regen_timer = 0.0
	_is_staggered        = true
	_stagger_timer       = STAGGER_DURATION
	_in_attack_state     = false
	_dodge_buffered      = false 
	_in_counter_window   = false
	_hitbox.combat_data.posture_damage = BASE_ATTACK_POSTURE_DMG
	_deflect_streak          = 0
	_streak_reset_timer      = 0.0
	_parry_sound.pitch_scale = 1.0
	_sprite.modulate     = Color(1.0, 0.3, 0.3)  
	_feedback.play_stagger_feedback(global_position)
	_play_knockdown_squash()
	if _in_parry_state:
		_exit_parry()
	_playback.start("MoveState", true)

func _play_knockdown_squash() -> void:
	VisualFX.squash_stretch(_sprite)


func _clear_hitbox() -> void:
	_hitbox.clear_hit_targets()
	var col := _hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.shape = null

func _get_streak_posture_mult() -> float:
	var levels := mini(_deflect_streak - 1, STREAK_MAX - 1)
	return COUNTER_POSTURE_MULT + levels * STREAK_POSTURE_PER_LEVEL

func _tick_regain(delta: float) -> void:
	if _regain_pool <= 0.0:
		return
	_regain_decay_timer += delta
	if _regain_decay_timer >= REGAIN_DECAY_DELAY:
		_regain_pool = maxf(0.0, _regain_pool - REGAIN_DECAY_RATE * delta)
	_update_regain_bar()

func _add_regain_pool(damage_taken: float) -> void:
	var missing_hp := stats.max_health - stats.health
	_regain_pool = minf(_regain_pool + damage_taken * REGAIN_RATIO, missing_hp)
	_regain_decay_timer = 0.0
	_update_regain_bar()

func _update_regain_bar() -> void:
	_regain_pool = minf(_regain_pool, stats.max_health - stats.health)
	_regain_bar.value = stats.health + _regain_pool

func _on_own_hitbox_landed(_target: Node) -> void:
	if _regain_pool > 0.0:
		var heal := minf(_regain_pool, stats.max_health - stats.health)
		stats.health += heal 
		_regain_pool -= heal
		_update_regain_bar()

	stats.posture = maxf(0.0, stats.posture - POSTURE_RECOVERY_ON_HIT)
	_posture_regen_timer = 0.0

func _flash_posture_bar() -> void:
	var tween := create_tween()
	tween.tween_property(_posture_bar, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.05)
	tween.tween_property(_posture_bar, "modulate", Color.WHITE, 0.15)

func lock_for_intro(duration: float) -> void:
	_is_intro_locked = true
	await get_tree().create_timer(duration, true, false, true).timeout
	_is_intro_locked = false

func skip_intro_lock() -> void:
	_is_intro_locked = false
