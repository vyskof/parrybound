extends BossBase

const Hit_effect := preload("res://hit_effect.tscn")

var defense: int = 0

func _on_boss_ready() -> void:
	boss_id = "golem"

func _on_boss_process(_delta: float) -> void:
	$Sprite2D.flip_h = direction.x < 0

func _on_boss_hit(_combat_data: CombatData) -> void:
	stats.health += defense
	_spawn_effect(Hit_effect, $Sprite2D.global_position)
	if stats.health <= stats.max_health * 0.5 and defense == 0:
		defense = 5
		_state_machine.change_state("ArmorBuff")

func _spawn_effect(scene: PackedScene, pos: Vector2) -> void:
	var effect := scene.instantiate() as Node2D
	get_parent().current_scene.add_child(effect)
	effect.global_position = pos
