class_name FeedbackOrchestrator extends Node

@export var hitstop: HitstopController
@export var camera: Camera2D

@export var perfect_parry_vfx: PackedScene
@export var guard_vfx: PackedScene
@export var player_hit_vfx: PackedScene
@export var stagger_vfx: PackedScene
@export var boss_hit_vfx: PackedScene

@export var perfect_parry_sfx: AudioStreamPlayer
@export var guard_sfx: AudioStreamPlayer
@export var hit_sfx: AudioStreamPlayer

@export var deflect_sparks_vfx: PackedScene



func play_parry_feedback(
	result: ParryResolver.Result,
	position: Vector2,
	combat_data: CombatData = null,
	streak: int = 1,
	is_just_frame: bool = false
) -> void:
	var hitstop_dur := combat_data.hitstop_duration if combat_data else 0.10
	match result:
		ParryResolver.Result.DEFLECT:
			_spawn_vfx(perfect_parry_vfx, position)
			_spawn_deflect_sparks(position, streak, is_just_frame)
			_play_sfx(perfect_parry_sfx, 0.10)
			var shake_mag := 0.3 + (mini(streak, 4) - 1) * 0.3
			if is_just_frame:
				shake_mag = 1.6
			camera.shake(shake_mag)
			hitstop.freeze(hitstop_dur)
		ParryResolver.Result.BLOCK:
			_spawn_vfx(guard_vfx, position)
			_play_sfx(guard_sfx, 0.5)
			hitstop.freeze(hitstop_dur * 0.5)
		_:
			pass

func play_hit_feedback(position: Vector2, combat_data: CombatData = null) -> void:
	_spawn_vfx(boss_hit_vfx, position)
	_play_sfx(hit_sfx)
	var hitstop_dur := combat_data.hitstop_duration if combat_data else 0.08
	hitstop.freeze(hitstop_dur)
	camera.shake(1.0)



func play_stagger_feedback(position: Vector2) -> void:
	_spawn_vfx(stagger_vfx, position)
	camera.shake(2.2)
	hitstop.freeze(0.22)

func play_boss_parried_feedback(
	result: ParryResolver.Result,
	position: Vector2
) ->void:
	match result:
		ParryResolver.Result.DEFLECT:
			_spawn_vfx(perfect_parry_vfx, position)
		ParryResolver.Result.BLOCK:
			_spawn_vfx(guard_vfx, position)


func _spawn_vfx(scene: PackedScene, pos: Vector2) -> void:
	if not scene:
		return
	var effect := scene.instantiate()
	if not effect:
		return
	else:
		if effect is Node2D:
			effect.global_position = pos
		get_tree().current_scene.add_child(effect)

func _play_sfx(
	player: AudioStreamPlayer,
	pitch_variation: float = 0.0
) -> void:
	if not player:
		return
	if pitch_variation > 0.0:
		player.pitch_scale = 1.0 + randf_range(
			-pitch_variation,
			pitch_variation
		)
	player.play()

func _spawn_deflect_sparks(pos: Vector2, streak: int, is_just_frame: bool) -> void:
	if not deflect_sparks_vfx:
		return
	if is_just_frame:
		var e1 := deflect_sparks_vfx.instantiate()
		e1.global_position = pos
		get_tree().current_scene.add_child(e1)
		e1.init(Color(0.9, 1.0, 1.0), 2.5, 1.2)
		
		var e2 := deflect_sparks_vfx.instantiate()
		e2.global_position = pos
		get_tree().current_scene.add_child(e2)
		e2.init(Color(1.0, 0.992, 0.959, 1.0), 1.2, 0.9) 
		return
		
	var color: Color
	var amount_mult: float
	var size_mult: float
	match mini(streak, 4):
		1:
			color       = Color(1.0, 0.90, 0.6)
			amount_mult = 1.0  
			size_mult   = 1.0
		2:
			color       = Color(1.0, 0.85, 0.5)
			amount_mult = 1.4
			size_mult   = 1.03
		3:
			color       = Color(1.0, 0.80, 0.4)
			amount_mult = 1.8
			size_mult   = 1.06
		_:
			color       = Color(1.0, 0.75, 0.3)
			amount_mult = 2.2
			size_mult   = 1.09
	
	var effect := deflect_sparks_vfx.instantiate()
	effect.global_position = pos
	get_tree().current_scene.add_child(effect)
	effect.init(color, amount_mult, size_mult)


func _ready() -> void:
	if not hitstop:
		push_warning("FeedbackOrchestrator na '%s': chybí HitstopController!" % get_parent().name)
	if not camera:
		push_warning("FeedbackOrchestrator na '%s': chybí Camera2D!" % get_parent().name)
