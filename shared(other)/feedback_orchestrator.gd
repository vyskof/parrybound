class_name FeedbackOrchestrator extends Node

@export var hitstop: HitstopController
@export var camera: Camera2D

@export var perfect_parry_vfx: PackedScene
@export var guard_vfx: PackedScene
@export var hit_vfx: PackedScene
@export var stagger_vfx: PackedScene

@export var perfect_parry_sfx: AudioStreamPlayer
@export var guard_sfx: AudioStreamPlayer
@export var hit_sfx: AudioStreamPlayer


func play_parry_feedback(
	result: ParryResolver.Result,
	position: Vector2
) -> void:
	match result:
		ParryResolver.Result.DEFLECT:
			_spawn_vfx(perfect_parry_vfx, position)
			_play_sfx(perfect_parry_sfx)
			camera.shake()
			hitstop.freeze(0.18)
		ParryResolver.Result.BLOCK:
			_spawn_vfx(guard_vfx, position)
			_play_sfx(guard_sfx)
			hitstop.freeze(0.06)
		_:
			pass

func play_hit_feedback(position: Vector2) -> void:
	_spawn_vfx(hit_vfx, position)
	_play_sfx(hit_sfx)
	hitstop.freeze(0.10)

func play_stagger_feedback(position: Vector2) -> void:
	_spawn_vfx(stagger_vfx, position)
	camera.shake()
	hitstop.freeze(0.20)

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
	var effect := scene.instantiate() as Node2D
	get_tree().current_scene.add_child(effect)
	effect.global_position = pos

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
