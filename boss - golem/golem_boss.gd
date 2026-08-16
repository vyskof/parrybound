extends BossBase

const Hit_effect := preload("res://effects/hit_effect.tscn")
const ArmorBreakSparks := preload("res://effects/deflect_sparks_effect.tscn")
const TauntLabel := preload("res://effects/boss_intro_label.tscn")

const ARMOR_TAUNT_LINES := [
	"My shell will not fall.",
	"Is that all?",
]

const ARMOR_MAX_HEALTH:          float = 60.0
const ARMOR_BREAK_POSTURE_BURST: float = 25.0

var DEF: int = 0
var armor_health: float = 0.0
var armor_used: bool = false

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
	if DEF > 0:
		_damage_armor(raw_damage)
	return maxf(0.0, raw_damage - DEF)

func _on_boss_hit(_combat_data: CombatData) -> void:
	_spawn_effect(Hit_effect, $Sprite2D.global_position)
	if stats.health <= stats.max_health / 2.0 and DEF == 0 and not armor_used:
		armor_used   = true
		DEF          = 5
		armor_health = ARMOR_MAX_HEALTH
		_show_taunt(ARMOR_TAUNT_LINES)
		_state_machine.change_state("ArmorBuff")

func _show_taunt(lines: Array) -> void:
	var label := TauntLabel.instantiate()
	get_tree().current_scene.add_child(label)
	if label.has_method("set_boss_name"):
		label.set_boss_name(lines[randi() % lines.size()])

func _damage_armor(raw_damage: float) -> void:
	armor_health = maxf(0.0, armor_health - raw_damage)
	if armor_health <= 0.0:
		_break_armor()

func _break_armor() -> void:
	DEF = 0
	stats.posture = minf(stats.posture + ARMOR_BREAK_POSTURE_BURST, stats.max_posture)
	_play_armor_break_feedback()

func _play_armor_break_feedback() -> void:
	var sparks := ArmorBreakSparks.instantiate()
	get_parent().add_child(sparks)
	sparks.global_position = $Sprite2D.global_position
	sparks.init(Color(0.75, 0.75, 0.8, 1.0), 2.0, 1.4)

	var cam := _player.get_node_or_null("Camera2D") if is_instance_valid(_player) else null
	if cam and cam.has_method("shake"):
		cam.shake(2.0)

	VisualFX.squash_stretch(_visual, Vector2(1.2, 0.8), 0.1, 0.3)

func _spawn_effect(scene: PackedScene, pos: Vector2) -> void:
	var effect := scene.instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = pos
