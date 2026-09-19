class_name Character extends CharacterBody2D


const LOW_HEALTH_RATIO    := 0.20
const FOOTSTEP_INTERVAL   := 0.34
const TINNITUS_THRESHOLD_RATIO := 0.3
const TINNITUS_DURATION        := 2.2

const AFTERIMAGE_INTERVAL := 0.05
const AFTERIMAGE_SCENE    := preload("res://effects/dodge_afterimage.tscn")

const ATTACK_TRAIL_TINT     := Color(1.0, 0.95, 0.75, 0.55)
const ATTACK_TRAIL_INTERVAL := 0.05
const ATTACK_TRAIL_FADE     := 0.16

const FAST_MOVE_TRAIL_TINT := Color(1.0, 0.85, 0.4, 0.5)
const FAST_MOVE_AFTERIMAGE_INTERVAL := 0.04

const SCENE_DEATH := preload("res://ui/deathscreen.tscn")
const SCENE_PAUSE := preload("res://ui/pause_menu.tscn")
const SCENE_TALENT_CHOICE := preload("res://ui/talent_choice_menu.tscn")
const SCENE_CHARACTER_MENU  := preload("res://ui/character_menu.tscn")


@export var stats: Stats
@export var tuning: CombatTuning
@export var footstep_sounds: Array[AudioStreamPlayer2D] = []

var input_vector      := Vector2.ZERO
var last_input_vector := Vector2.DOWN
var is_invincible     := false

var _is_dodging        := false
var _dodge_direction   := Vector2.ZERO
var _stamina_regen_timer : float = 0.0
var _dodge_cooldown_timer : float = 0.0

var _is_fast_moving: bool = false
var _fast_move_timer: float = 0.0
var _fast_move_cooldown_timer: float = 0.0
var _fast_move_afterimage_timer: float = 0.0

var _stamina_blink_tween: Tween = null

var _footstep_timer: float = 0.0
var _tinnitus_active: bool = false
var _tinnitus_filter: AudioEffectLowPassFilter = null
var _talent_menu: Node = null

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
var _parry_state_timer   : float = 0.0
var _parry_cooldown_timer: float = 0.0
var _buffered_action     : StringName = &""
var _input_buffer_timer  : float = 0.0

var _attack_elapsed     : float = 0.0
var _attack_speed       : float = 1.0
var _attack_dir         : Vector2 = Vector2.RIGHT
var _attack_sequence_id: int = 0
var _low_health_active: bool = false

var _is_intro_locked: bool = false

var _in_counter_window  : bool  = false
var _counter_timer      : float = 0.0

var _attack_damage_mult: float = 1.0
var _stamina_regen_bonus: float = 0.0
var _deflect_stamina_mult: float = 1.0
var _hit_posture_mult: float = 1.0
var _stamina_regen_mult: float = 1.0
var _counter_window_bonus: float = 0.0
var _streak_damage_mult: float = 1.0
var _dodge_stamina_mult: float = 1.0
var _fast_move_cooldown_mult: float = 1.0
var _low_stamina_penalty_mult: float = 1.0

var _can_open_menu      := true

@onready var _animation_tree   : AnimationTree        = $AnimationTree
@onready var _hurtbox          : Hurtbox              = $Hurtbox
@onready var _health_bar       : TextureProgressBar   = $CanvasLayer/TextureProgressBar
@onready var _posture_bar      : TextureProgressBar   = $CanvasLayer/TexturePostureBar
@onready var _stamina_bar      : TextureProgressBar   = $CanvasLayer/TextureStaminaBar
@onready var _sprite           : Sprite2D             = $Sprite2D
@onready var _parry_resolver   : ParryResolver        = $ParryResolver
@onready var _feedback         : FeedbackOrchestrator = $FeedbackOrchestrator
@onready var _hitbox           : Hitbox               = $Hitbox
@onready var _attack_shape     : CollisionShape2D     = $Hitbox/CollisionShape2D
@onready var _regain_bar       : TextureProgressBar   = $CanvasLayer/RegainBar
@onready var _footstep_player  : AudioStreamPlayer2D  = $FootstepSound
@onready var _heartbeat_player : AudioStreamPlayer    = $HeartbeatSound
@onready var _breath_player    : AudioStreamPlayer    = $BreathSound
@onready var _tinnitus_player  : AudioStreamPlayer    = $TinnitusSound
@onready var _souls_label      : Label                = $CanvasLayer/SoulsLabel


var _playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	
	_playback = _animation_tree.get("parameters/StateMachine/playback")

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

	GameManager.apply_save_to_player(self)
	_refresh_bars_after_save_applied()
	GameManager.souls_changed.connect(_on_souls_changed)
	_on_souls_changed(GameManager.get_souls())
	GameManager.leveled_up.connect(_on_leveled_up)
	refresh_attribute_bonuses()
	refresh_talents()
	_try_show_talent_choice.call_deferred()

func _on_leveled_up() -> void:
	await get_tree().create_timer(2.0, true, false, true).timeout
	_try_show_talent_choice()


func _try_show_talent_choice() -> void:
	if is_instance_valid(_talent_menu) or not GameManager.has_pending_talent_pick():
		return
	_talent_menu = SCENE_TALENT_CHOICE.instantiate()
	get_tree().root.add_child(_talent_menu)
	_talent_menu.setup(GameManager.get_talent_offer())
	_talent_menu.closed.connect(_on_talent_menu_closed)


func _on_talent_menu_closed() -> void:
	_talent_menu = null
	_try_show_talent_choice.call_deferred()

func get_current_attack_damage() -> float:
	return tuning.tuning.base_attack_damage * _attack_damage_mult

func get_current_stamina_regen() -> float:
	return (tuning.stamina_regen_rate + _stamina_regen_bonus) * _stamina_regen_mult

func refresh_attribute_bonuses() -> void:
	var strength_level := GameManager.get_attribute_level("strength")
	var agility_level := GameManager.get_attribute_level("agility")
	_attack_damage_mult  = pow(1.08, float(strength_level))
	_stamina_regen_bonus = maxf(0.0, float(agility_level))

func refresh_talents() -> void:
	_deflect_stamina_mult      = 1.0
	_hit_posture_mult          = 1.0
	_stamina_regen_mult        = 1.0
	_counter_window_bonus      = 0.0
	_streak_damage_mult        = 1.0
	_dodge_stamina_mult        = 1.0
	_fast_move_cooldown_mult   = 1.0
	_low_stamina_penalty_mult  = 1.0

	for talent_id in GameManager.get_equipped_talents():
		var effect := TalentData.get_talent(talent_id)
		if effect:
			set(effect.stat_key, effect.stat_value)

func refresh_max_value_bars() -> void:
	_health_bar.max_value  = stats.max_health
	_health_bar.value      = stats.health
	_stamina_bar.max_value = stats.max_stamina
	_stamina_bar.value     = stats.stamina
	_regain_bar.max_value  = stats.max_health


func _refresh_bars_after_save_applied() -> void:
	_health_bar.max_value  = stats.max_health
	_health_bar.value      = stats.health
	_posture_bar.max_value = float(stats.max_posture)
	_stamina_bar.max_value = stats.max_stamina
	stats.stamina = stats.max_stamina
	_stamina_bar.value = stats.stamina
	_regain_bar.max_value = stats.max_health
	_regain_bar.value     = stats.health

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused and _can_open_menu and not GameManager.in_boss_fight:
		get_tree().root.add_child(SCENE_PAUSE.instantiate())
	if event.is_action_pressed("character_menu") and not get_tree().paused and _can_open_menu and not GameManager.in_boss_fight:
		var menu := SCENE_CHARACTER_MENU.instantiate()
		get_tree().root.add_child(menu)
		menu.setup(self)

# ─── Main loop ────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _is_intro_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_parry_resolver.tick(delta)
	_tick_parry_timers(delta)
	_tick_attack(delta)
	_tick_input_buffer(delta)
	_tick_posture_regen(delta)
	_tick_knockback(delta)
	_tick_stagger(delta)
	_tick_stamina_regen(delta)
	_tick_dodge_cooldown(delta)
	_tick_fast_move(delta)
	_tick_combo_pulse(delta)
	_tick_counter_window(delta)
	_tick_streak_reset(delta)
	_tick_regain(delta)


	if _is_dodging:
		_capture_buffered_input()
		velocity = _dodge_direction * tuning.dodge_speed + _knockback_velocity
		move_and_slide()
		return


	if _knockback_lock > 0.0:
		_capture_buffered_input()
		_knockback_lock -= delta
		velocity = _knockback_velocity
		move_and_slide()
		return

	if _is_staggered:
		_capture_buffered_input()
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

	if _try_consume_buffered_input():
		return

	if Input.is_action_just_pressed("attack"):
		_enter_attack()
		return

	if Input.is_action_just_pressed("parry"):
		_request_parry()
		if _in_parry_state:
			return

	if Input.is_action_just_pressed("dodge"):
		_enter_dodge()
		return

	if Input.is_action_just_pressed("fast_move"):
		_try_start_fast_move()

	var move_speed = tuning.fast_move_speed if _is_fast_moving else tuning.speed
	if stats.stamina <= stats.max_stamina * tuning.low_stamina_ratio:
		var penalty := 1.0 - tuning.low_stamina_speed_mult
		move_speed *= 1.0 - penalty * _low_stamina_penalty_mult

	velocity = input_vector * move_speed + _knockback_velocity
	move_and_slide()
	_tick_footsteps(_delta, input_vector.length())


func _process_attack() -> void:
	_capture_buffered_input()
	if _is_in_attack_recovery() and Input.is_action_just_pressed("parry") and _can_start_parry():
		_cancel_attack()
		_enter_parry()
		return

	if Input.is_action_just_pressed("dodge") and _is_in_attack_recovery():
		var cancel_cost := tuning.dodge_stamina_cost * tuning.dodge_cancel_stamina_mult
		if stats.stamina >= cancel_cost and _dodge_cooldown_timer <= 0.0:
			_clear_input_buffer()
			_cancel_attack()
			_enter_dodge()
			return
	
	var move_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = move_input * tuning.speed * tuning.attack_move_speed_mult + _knockback_velocity
	move_and_slide()


func _process_parry() -> void:
	_capture_buffered_input()
	velocity = _knockback_velocity
	move_and_slide()

func _enter_attack() -> void:
	if _in_attack_state:
		return
	if stats.stamina < tuning.attack_stamina_cost:
		return
	_in_attack_state = true
	_can_open_menu = false
	_attack_elapsed = 0.0
	stats.stamina -= tuning.attack_stamina_cost
	_stamina_regen_timer = 0.0
	var streak_bonus := _streak_damage_mult if _deflect_streak > 0 else 1.0
	if _hitbox.combat_data:
		_hitbox.combat_data.damage = tuning.base_attack_damage * _attack_damage_mult * streak_bonus

	var is_riposte := _in_counter_window
	_attack_speed = tuning.riposte_attack_speed if is_riposte else (tuning.combo_attack_speed if _combo_pulse_timer > 0.0 else 1.0)
	_animation_tree.set("parameters/TimeScale/scale", (0.6 / _attack_total_base()) * _attack_speed)

	var mouse_dir := (get_global_mouse_position() - global_position).normalized()
	if mouse_dir == Vector2.ZERO:
		mouse_dir = last_input_vector
	_attack_dir = mouse_dir
	_animation_tree.set(
		"parameters/StateMachine/AttackState/blend_position",
		Vector2(mouse_dir.x, -mouse_dir.y)
	)
	_hitbox.position = Vector2(0.0, tuning.body_center_offset) + mouse_dir * tuning.attack_reach
	_hitbox.rotation = mouse_dir.angle()
	_clear_hitbox()
	_playback.travel("AttackState")

	if is_riposte:
		_play_riposte_lunge(mouse_dir)
	
	_attack_sequence_id += 1
	_spawn_attack_trail(_attack_sequence_id)


func _attack_total_base() -> float:
	return tuning.attack_startup + tuning.attack_active + tuning.attack_recovery


func _tick_attack(delta: float) -> void:
	if not _in_attack_state:
		return
	var previous := _attack_elapsed
	_attack_elapsed += delta * _attack_speed
	var active_start := tuning.attack_startup
	var active_end   := active_start + tuning.attack_active

	if previous < active_start and _attack_elapsed >= active_start:
		_set_attack_hitbox_enabled(true)
	if previous < active_end and _attack_elapsed >= active_end:
		_clear_hitbox()
	if _attack_elapsed >= _attack_total_base():
		_end_attack()


func _is_in_attack_recovery() -> bool:
	return _attack_elapsed >= tuning.attack_startup + tuning.attack_active


func _set_attack_hitbox_enabled(enabled: bool) -> void:
	if _attack_shape:
		_attack_shape.disabled = not enabled


func _cancel_attack() -> void:
	_in_attack_state = false
	_can_open_menu   = true
	_attack_elapsed  = 0.0
	_clear_hitbox()
	_animation_tree.set("parameters/TimeScale/scale", 1.0)
	_playback.start("MoveState", true)


func _end_attack() -> void:
	_cancel_attack()
	_combo_pulse_timer = tuning.combo_pulse_window
	_try_consume_buffered_input()


func _play_riposte_lunge(dir: Vector2) -> void:
	var target := global_position + dir * tuning.riposte_lunge_distance
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var flash := create_tween()
	flash.tween_property(_sprite, "modulate", Color(1.4, 1.4, 1.0, 1.0), 0.05)
	flash.tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _can_start_parry() -> bool:
	return not _in_parry_state and _parry_cooldown_timer <= 0.0



func _request_parry() -> void:
	if _can_start_parry():
		_enter_parry()
	else:
		_buffer_action(&"parry")


func _enter_parry() -> void:
	if not _can_start_parry():
		return
	if _buffered_action == &"parry":
		_clear_input_buffer()
	_parry_cooldown_timer = tuning.parry_cooldown
	_parry_state_timer    = tuning.parry_action_duration
	_in_parry_state = true
	_can_open_menu = false
	_parry_resolver.try_start_deflect()
	var mouse_dir := (get_global_mouse_position() - global_position).normalized()
	_update_blend_positions(Vector2(mouse_dir.x, -mouse_dir.y))
	_playback.travel("ParryState")


func _exit_parry() -> void:
	_in_parry_state = false
	_parry_state_timer = 0.0
	_can_open_menu = true
	_parry_resolver.stop_deflect()
	_playback.start("MoveState", true)



func _tick_parry_timers(delta: float) -> void:
	if _parry_cooldown_timer > 0.0:
		_parry_cooldown_timer -= delta
	if not _in_parry_state:
		return
	_parry_state_timer -= delta
	if _parry_state_timer <= 0.0:
		_exit_parry()



func _capture_buffered_input() -> void:
	if Input.is_action_just_pressed("parry"):
		_buffer_action(&"parry")
	elif Input.is_action_just_pressed("dodge"):
		_buffer_action(&"dodge")
	elif Input.is_action_just_pressed("attack"):
		_buffer_action(&"attack")


func _buffer_action(action: StringName) -> void:
	_buffered_action    = action
	_input_buffer_timer = tuning.input_buffer_time


func _clear_input_buffer() -> void:
	_buffered_action    = &""
	_input_buffer_timer = 0.0


func _tick_input_buffer(delta: float) -> void:
	if _buffered_action == &"":
		return
	_input_buffer_timer -= delta
	if _input_buffer_timer <= 0.0:
		_clear_input_buffer()


func _try_consume_buffered_input() -> bool:
	match _buffered_action:
		&"parry":
			if not _can_start_parry():
				return false   
			_enter_parry()
			return true
		&"dodge":
			_clear_input_buffer()
			_enter_dodge()
			return _is_dodging
		&"attack":
			_clear_input_buffer()
			_enter_attack()
			return _in_attack_state
	return false


func _on_hurt(combat_data: CombatData, hitbox: Hitbox) -> void:
	if is_invincible:
		return

	var result := _parry_resolver.evaluate(combat_data)

	match result:
		ParryResolver.Result.DEFLECT:
			_deflect_streak     = mini(_deflect_streak + 1, tuning.streak_max)
			_streak_reset_timer = 0.0

			var posture_mult := _get_streak_posture_mult()
			stats.stamina += tuning.deflect_stamina_reward * _deflect_stamina_mult

			stats.posture = maxf(0.0, stats.posture - tuning.parry_posture_restore)
			_posture_regen_timer = 0.0
			_in_counter_window = true
			_counter_timer     = tuning.counter_window_duration + _counter_window_bonus
			_hitbox.combat_data.posture_damage = tuning.base_attack_posture_dmg * posture_mult

			var attacker_position: Vector2 = hitbox.owner.global_position if hitbox and is_instance_valid(hitbox.owner) else Vector2.ZERO
			_feedback.play_parry_feedback(ParryResolver.Result.DEFLECT, global_position, combat_data, _deflect_streak, attacker_position)
			_apply_parry_pushback(hitbox, tuning.deflect_pushback)

			if hitbox.owner.has_method("receive_parry"):
				var reward := combat_data.parry_posture_reward if combat_data else 35.0
				hitbox.owner.receive_parry(reward)

			_parry_state_timer    = minf(_parry_state_timer, tuning.deflect_recovery)
			_parry_cooldown_timer = 0.0

		ParryResolver.Result.NONE:
			if _in_parry_state:
				_exit_parry()
			var dmg  := combat_data.damage          if combat_data else (hitbox.damage if hitbox else 10.0)
			var pdmg := combat_data.posture_damage   if combat_data else 5.0
			stats.health  -= dmg
			_add_regain_pool(dmg)
			_pulse_damage_vignette(dmg)
			stats.posture += pdmg * _hit_posture_mult
			_posture_regen_timer = 0.0
			if hitbox and combat_data and combat_data.knockback_force > 0.0:
				_apply_knockback(hitbox, combat_data)
			var attacker_pos = hitbox.owner.global_position if hitbox and is_instance_valid(hitbox.owner) else Vector2.ZERO
			_feedback.play_hit_feedback(global_position, combat_data, attacker_pos)
			if not _is_staggered:
				_flash_red()
			_start_invincibility(0.5)


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
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, tuning.knockback_friction * delta)

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
	_posture_regen_timer += delta
	if _posture_regen_timer >= tuning.posture_regen_delay:
		var hp_ratio: float = clampf(stats.health / maxf(stats.max_health, 1.0), 0.0, 1.0)
		var factor: float = lerpf(tuning.posture_regen_low_hp_mult, 1.0, hp_ratio)
		stats.posture = maxf(0.0, stats.posture - tuning.posture_regen_rate * factor * delta)

func _tick_stamina_regen(delta: float) -> void:
	if stats.stamina >= stats.max_stamina:
		return
	_stamina_regen_timer += delta
	if _stamina_regen_timer >= tuning.stamina_regen_delay:
		stats.stamina += (tuning.stamina_regen_rate + _stamina_regen_bonus) * _stamina_regen_mult * delta

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
		_hitbox.combat_data.posture_damage = tuning.base_attack_posture_dmg

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
	if _streak_reset_timer >= tuning.streak_reset_time:
		_deflect_streak     = 0
		_streak_reset_timer = 0.0



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
	var dodge_cost := tuning.dodge_stamina_cost * _dodge_stamina_mult
	if stats.stamina < dodge_cost:
		return
	stats.stamina -= dodge_cost
	_stamina_regen_timer = 0.0
	_is_dodging = true
	_can_open_menu = false
	var live_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if live_input != Vector2.ZERO:
		last_input_vector = live_input
	_dodge_direction = live_input if live_input != Vector2.ZERO else -last_input_vector
	_start_invincibility(tuning.dodge_iframes)
	_sprite.modulate.a = 0.5
	
	var elapsed := 0.0
	while elapsed < tuning.dodge_duration:
		_spawn_afterimage()
		await get_tree().create_timer(AFTERIMAGE_INTERVAL, true, false, true).timeout
		elapsed += AFTERIMAGE_INTERVAL
	
	_is_dodging = false
	_can_open_menu = true
	_dodge_cooldown_timer = tuning.dodge_cooldown
	_sprite.modulate.a = 1.0

func _tick_dodge_cooldown(delta: float) -> void:
	if _dodge_cooldown_timer > 0.0:
		_dodge_cooldown_timer -= delta

func _try_start_fast_move() -> void:
	if _is_fast_moving or _fast_move_cooldown_timer > 0.0:
		return
	if stats.stamina < tuning.fast_move_stamina_cost:
		return

	stats.stamina -= tuning.fast_move_stamina_cost
	_stamina_regen_timer = 0.0
	_is_fast_moving = true
	_fast_move_timer = tuning.fast_move_duration
	_sprite.modulate.a = 0.6


func _tick_fast_move(delta: float) -> void:
	if _fast_move_cooldown_timer > 0.0:
		_fast_move_cooldown_timer -= delta

	if not _is_fast_moving:
		return

	_fast_move_timer -= delta

	_fast_move_afterimage_timer -= delta
	if _fast_move_afterimage_timer <= 0.0:
		_fast_move_afterimage_timer = FAST_MOVE_AFTERIMAGE_INTERVAL
		_spawn_afterimage(FAST_MOVE_TRAIL_TINT, 0.09)

	if _fast_move_timer <= 0.0:
		_is_fast_moving = false
		_fast_move_cooldown_timer = tuning.fast_move_cooldown * _fast_move_cooldown_mult
		_sprite.modulate.a = 1.0


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
	_tinnitus_filter = filter

	_tinnitus_player.play()

	var tween := create_tween()
	tween.tween_method(
		func(hz: float): filter.cutoff_hz = hz,
		700.0, 20000.0, TINNITUS_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	_remove_tinnitus_filter()


func _remove_tinnitus_filter() -> void:
	if _tinnitus_filter == null:
		return
	AudioBusUtil.remove_effect_safe(AudioServer.get_bus_index("Master"), _tinnitus_filter)
	_tinnitus_filter = null
	_tinnitus_active = false


func _exit_tree() -> void:
	_remove_tinnitus_filter()



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
	_stagger_timer       = tuning.stagger_duration
	_cancel_attack()
	_clear_input_buffer()
	_in_counter_window   = false
	_hitbox.combat_data.posture_damage = tuning.base_attack_posture_dmg
	_deflect_streak          = 0
	_streak_reset_timer      = 0.0
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
	_set_attack_hitbox_enabled(false)

func _get_streak_posture_mult() -> float:
	var levels := mini(_deflect_streak - 1, tuning.streak_max - 1)
	return tuning.counter_posture_mult + levels * tuning.streak_posture_per_level

func _tick_regain(delta: float) -> void:
	if _regain_pool <= 0.0:
		return
	_regain_decay_timer += delta
	if _regain_decay_timer >= tuning.regain_decay_delay:
		_regain_pool = maxf(0.0, _regain_pool - tuning.regain_decay_rate * delta)
	_update_regain_bar()

func _add_regain_pool(damage_taken: float) -> void:
	var missing_hp := stats.max_health - stats.health
	_regain_pool = minf(_regain_pool + damage_taken * tuning.regain_ratio, missing_hp)
	_regain_decay_timer = 0.0
	_update_regain_bar()

func _update_regain_bar() -> void:
	_regain_pool = minf(_regain_pool, stats.max_health - stats.health)
	_regain_bar.value = stats.health + _regain_pool

func _on_own_hitbox_landed(_target: Node) -> void:
	_feedback.play_own_hit_feedback(_hitbox.global_position, _attack_dir)
	if _regain_pool > 0.0:
		var heal := minf(_regain_pool, stats.max_health - stats.health)
		stats.health += heal 
		_regain_pool -= heal
		_update_regain_bar()

	stats.posture = maxf(0.0, stats.posture - tuning.posture_recovery_on_hit)
	_posture_regen_timer = 0.0

func lock_for_intro(duration: float) -> void:
	_is_intro_locked = true
	await get_tree().create_timer(duration, true, false, true).timeout
	_is_intro_locked = false

func skip_intro_lock() -> void:
	_is_intro_locked = false

func _on_souls_changed(new_amount: int) -> void:
	if _souls_label:
		_souls_label.text = str(new_amount)
