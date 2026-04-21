extends BossBase

const Stagger_effect := preload("res://effects/stagger_effect.tscn")
const Hit_effect := preload("res://effects/hit_effect.tscn")
const Phase_two_effect := preload("res://effects/phase_two_effect.tscn")

var phase_two: bool = false

func _on_boss_ready() -> void:
	boss_id = "grim_reaper"
	stats.posture_changed.connect(_on_posture_changed)

func _on_posture_changed(new_posture: float) -> void:
	var bar := get_node_or_null("UI/TexturePostureBar")
	if bar:
		bar.value = new_posture


func _on_boss_process(_delta: float) -> void:
	$AnimatedSprite2D.flip_h = direction.x < 0

func _on_boss_hit(_combat_data: CombatData) -> void:
	_spawn_effect(Hit_effect, $AnimatedSprite2D.global_position)
	if stats.health <= stats.max_health /2.0 and not phase_two:
		_start_phase_two()

func _start_phase_two() -> void:
	phase_two = true
	_spawn_effect(Phase_two_effect, $AnimatedSprite2D.global_position)
	_state_machine.change_state("PhaseTwo")

func _spawn_effect(scene: PackedScene, pos: Vector2) -> void:
	var effect := scene.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos

func _on_posture_broken() -> void:
	stats.posture        = 0.0
	_posture_regen_timer = 0.0
	_spawn_effect(Stagger_effect, $AnimatedSprite2D.global_position)
	_state_machine.change_state("Stagger")
