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
	combat_data: CombatData = null
) -> void:
	var hitstop_dur := combat_data.hitstop_duration if combat_data else 0.10
	match result:
		ParryResolver.Result.DEFLECT:
			_spawn_vfx(perfect_parry_vfx, position)
			_spawn_vfx(deflect_sparks_vfx, position)
			_play_sfx(perfect_parry_sfx, 0.10)
			camera.shake(0.5)
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

func _ready() -> void:
	if not hitstop:
		push_warning("FeedbackOrchestrator na '%s': chybí HitstopController!" % get_parent().name)
	if not camera:
		push_warning("FeedbackOrchestrator na '%s': chybí Camera2D!" % get_parent().name)
