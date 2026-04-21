extends BossBase

const Stagger_effect := preload("res://stagger_effect.tscn")
const Hit_effect := preload("res://hit_effect.tscn")
const Phase_two_effect := preload("res://phase_two_effect.tscn")

var phase_two: bool = false

func _on_boss_ready() -> void:
	boss_id = "grim_reaper"

func _on_boss_process(_delta: float) -> void:
	$AnimatedSprite2D.flip_h = direction.x < 0

func _on_boss_hit(_combat_data: CombatData) -> void:
	_spawn_effect(Hit_effect, $AnimatedSprite2D.global_position)
	if stats.health <= stats.max_health * 0.5 and not phase_two:
		_start_phase_two()

func _start_phase_two() -> void:
	phase_two = true
	_spawn_effect(Phase_two_effect, $AnimatedSprite2D.global_position)
	_state_machine.change_state("PhaseTwo")

func _spawn_effect(scene: PackedScene, pos: Vector2) -> void:
	var effect := scene.instantiate() as Node2D
	get_parent().current_scene.add_child(effect)
	effect.global_position = pos
