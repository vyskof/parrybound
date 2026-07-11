extends BossBase

const Hit_effect := preload("res://effects/hit_effect.tscn")

var DEF: int = 0

func _on_boss_ready() -> void:
	boss_id = "golem"
	stats.posture_changed.connect(_on_posture_changed)

func _on_posture_changed(new_posture: float) -> void:
	var bar := get_node_or_null("UI/TexturePostureBar")
	if bar:
		bar.value = new_posture


func _on_boss_process(_delta: float) -> void:
	$Sprite2D.flip_h = direction.x < 0

func _calculate_damage(raw_damage: float, _combat_data: CombatData = null, _hitbox: Hitbox = null) -> float:
	return maxf(0.0, raw_damage - DEF)

func _on_boss_hit(_combat_data: CombatData) -> void:
	_spawn_effect(Hit_effect, $Sprite2D.global_position)
	if stats.health <= stats.max_health /2.0 and DEF == 0:
		DEF = 5
		_state_machine.change_state("ArmorBuff")

func _spawn_effect(scene: PackedScene, pos: Vector2) -> void:
	var effect := scene.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos

func _on_posture_broken() -> void:
	stats.posture        = 0.0
	_posture_regen_timer = 0.0
	_state_machine.change_state("Stagger")
