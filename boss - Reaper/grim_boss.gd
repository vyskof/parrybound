extends BossBase

const Stagger_effect := preload("res://effects/stagger_effect.tscn")
const Phase_two_effect := preload("res://effects/phase_two_effect.tscn")
const Hit_effect := preload("res://effects/hit_effect.tscn")
const TauntLabel := preload("res://effects/boss_intro_label.tscn")

const PHASE_TWO_LINES := [
	"You will not leave this place.",
	"Enough games.",
]

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
	_show_taunt(PHASE_TWO_LINES)
	_state_machine.change_state("PhaseTwo")

func _show_taunt(lines: Array) -> void:
	var label := TauntLabel.instantiate()
	get_tree().current_scene.add_child(label)
	if label.has_method("set_boss_name"):
		label.set_boss_name(lines[randi() % lines.size()])

func _spawn_effect(scene: PackedScene, pos: Vector2) -> void:
	var effect := scene.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos

func _on_boss_staggered() -> void:
	_spawn_effect(Stagger_effect, $AnimatedSprite2D.global_position)
