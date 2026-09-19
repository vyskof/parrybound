class_name BossBase extends CharacterBody2D

@export var stats: Stats
@export var posture_regen_delay : float = 2.0
@export var posture_regen_speed : float = 20.0
@export var boss_id: String = "unnamed_boss"
@export var souls_reward: int = 150


@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _state_machine = $FiniteStateMachine

signal boss_defeated(id: String)
signal encounter_started

var direction: Vector2
var _posture_regen_timer: float = 0.0
var _player: Node2D
var _is_dead: bool = false 

var _posture_bar: Node

@onready var _visual: Node2D = find_child("*Sprite2D", true, false)
@onready var _posture_arc: Node = get_node_or_null("PostureArc")
@onready var _boss_ui: CanvasLayer = get_node_or_null("UI")

var _hp_critical_active: bool = false
var _hp_critical_tween: Tween

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	stats.health = stats.max_health
	stats.posture  = 0.0 
	stats.posture_broken.connect(_on_posture_broken)
	stats.posture_changed.connect(_update_posture_lean)
	stats.posture_changed.connect(_update_posture_arc)
	stats.health_changed.connect(_on_health_changed)
	stats.no_health.connect(_on_no_health)
	_hurtbox.hurt.connect(_on_hurt)
	set_physics_process(false)
	_on_boss_ready()
	_posture_bar = get_node_or_null("UI/TexturePostureBar")
	encounter_started.connect(func(): GameManager.in_boss_fight = true)
	boss_defeated.connect(func(_id): GameManager.in_boss_fight = false)

func _exit_tree() -> void:
	GameManager.in_boss_fight = false

func _on_boss_ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if direction.length() > 33.0:
		velocity = direction.normalized() * 60.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	if velocity.length() > 1.0:
		move_and_slide()

func _process(delta: float) -> void:
	if _is_dead:
		return
	_tick_posture_regen(delta)
	_update_direction()
	_on_boss_process(delta)

func _on_boss_process(_delta: float) -> void:
	pass

func receive_parry(posture_dmg: float) -> void:
	stats.posture += posture_dmg
	_posture_regen_timer = 0.0
	_interrupt_current_action()
	if is_instance_valid(_player):
		var push_dir := (global_position - _player.global_position).normalized()
		velocity += push_dir * 30.0

func _interrupt_current_action() -> void:
	set_physics_process(false)
	if not has_node("InterruptTimer"):
		var timer := Timer.new()
		timer.name = "InterruptTimer"
		timer.one_shot = true
		timer.wait_time = 0.20
		timer.timeout.connect(_on_interrupt_timeout)
		add_child(timer)
	$InterruptTimer.start()

func _on_interrupt_timeout() -> void:
	if not _is_dead and not is_vulnerable:
		set_physics_process(true)


const BloodSprayEffect := preload("res://effects/blood_spray_effect.tscn")

func _on_hurt(combat_data: CombatData, hitbox: Hitbox) -> void:
	if _is_dead:
		return


	var raw_dmg: float
	if combat_data:
		raw_dmg = combat_data.damage
		stats.posture += combat_data.posture_damage
	else:
		raw_dmg = hitbox.damage if hitbox else 10.0
		stats.posture += 5.0

	stats.health -= _calculate_damage(raw_dmg, combat_data, hitbox)
	_posture_regen_timer = 0.0
	_spawn_blood_spray(hitbox)
	_on_boss_hit(combat_data)

func _spawn_blood_spray(hitbox: Hitbox, amount_mult: float = 1.0) -> void:
	if not is_instance_valid(hitbox) or not is_instance_valid(hitbox.owner):
		return
	var dir = global_position - hitbox.owner.global_position
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var spray := BloodSprayEffect.instantiate()
	get_parent().add_child(spray)
	spray.global_position = global_position
	spray.init(dir, amount_mult)

func _on_boss_hit(_combat_data: CombatData) -> void:
	pass

func _on_health_changed(new_health: float) -> void:
	var bar := get_node_or_null("UI/TextureProgressBar")
	if bar:
		bar.value = float(new_health)

	_punch_boss_ui()
	_update_hp_critical_state(new_health, bar)

func _punch_boss_ui() -> void:
	if not _boss_ui or _is_dead:
		return
	var tween := create_tween()
	tween.tween_property(_boss_ui, "scale", Vector2(1.05, 1.05), 0.06)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(_boss_ui, "scale", Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _update_hp_critical_state(new_health: float, bar: TextureProgressBar) -> void:
	if not bar:
		return
	var is_critical := new_health > 0.0 and new_health <= stats.max_health * 0.25
	if is_critical == _hp_critical_active:
		return
	_hp_critical_active = is_critical

	if is_critical:
		_hp_critical_tween = create_tween().set_loops()
		_hp_critical_tween.tween_property(bar, "modulate", Color(1.6, 0.5, 0.5, 1.0), 0.35)
		_hp_critical_tween.tween_property(bar, "modulate", Color.WHITE, 0.35)
	elif _hp_critical_tween:
		_hp_critical_tween.kill()
		_hp_critical_tween = null
		bar.modulate = Color.WHITE


var is_vulnerable: bool = false   

const StaggerImpactSparks := preload("res://effects/deflect_sparks_effect.tscn")

func _on_posture_broken() -> void:
	stats.posture = 0.0
	_posture_regen_timer = 0.0
	_apply_posture_break_knockback()
	_play_stagger_screen_feedback()
	_on_boss_staggered()
	_state_machine.change_state("Stagger")

func _on_boss_staggered() -> void:
	pass   # hook pro boss-specifický vizuál při staggeru (vlastní sprite burst atd.)

func _play_stagger_screen_feedback() -> void:
	var cam := _player.get_node_or_null("Camera2D") if is_instance_valid(_player) else null
	if cam and cam.has_method("shake"):
		cam.shake(4.5)
	if cam and cam.has_method("zoom_pulse"):
		cam.zoom_pulse(Vector2(0.85, 0.85), 0.4)

	ChromaticAberration.pulse(0.016, 0.4)
	FlashOverlay.flash(Color(1.0, 0.95, 0.7, 1.0), 0.05, 0.2)
	Hitstop.freeze(0.22)

	if _visual:
		var sparks := StaggerImpactSparks.instantiate()
		get_parent().add_child(sparks)
		sparks.global_position = _visual.global_position
		if sparks.has_method("init"):
			sparks.init(Color(1.0, 0.9, 0.5, 1.0), 0.02, 0.1)

func _apply_posture_break_knockback() -> void:
	if not is_instance_valid(_player):
		return
	var push_dir := (global_position - _player.global_position).normalized()
	var target := global_position + push_dir * 20.0
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_no_health() -> void:
	_is_dead = true
	set_physics_process(false)
	var hp_bar := get_node_or_null("UI/TextureProgressBar")
	var posture_bar := get_node_or_null("UI/TexturePostureBar")
	if hp_bar: hp_bar.visible = false
	if posture_bar: posture_bar.visible = false
	if _posture_arc and _posture_arc.has_method("set_posture_ratio"):
		_posture_arc.set_posture_ratio(0.0)
	if _hp_critical_tween:
		_hp_critical_tween.kill()
		_hp_critical_tween = null
	_state_machine.change_state("Death")
	GameManager.mark_boss_defeated(boss_id)
	GameManager.add_souls(souls_reward)
	GameManager.level_up()
	GameManager.save_to_slot()
	boss_defeated.emit(boss_id)

func _tick_posture_regen(delta: float) -> void:
	if stats.posture <= 0:
		_posture_regen_timer = 0.0
		return
	_posture_regen_timer += delta
	
	if _posture_regen_timer >= posture_regen_delay:
		stats.posture = maxf(0.0, stats.posture - posture_regen_speed * delta)
	if _posture_bar:
		_posture_bar.value = stats.posture

func _update_direction() -> void:
	if not is_instance_valid(_player):
		return
	direction = _player.global_position - global_position

func _calculate_damage(raw_damage: float, _combat_data: CombatData = null, _hitbox: Hitbox = null) -> float:
	return raw_damage

func _update_posture_lean(new_posture: float) -> void:
	if not _visual or _is_dead:
		return
	var ratio: float = clampf(new_posture / float(stats.max_posture), 0.0, 1.0)
	var lean_angle: float = deg_to_rad(6.0) * ratio
	var tween := create_tween()
	tween.tween_property(_visual, "rotation", lean_angle, 0.25).set_trans(Tween.TRANS_SINE)

func _update_posture_arc(new_posture: float) -> void:
	if not _posture_arc or not _posture_arc.has_method("set_posture_ratio"):
		return
	_posture_arc.set_posture_ratio(new_posture / float(stats.max_posture))
	
