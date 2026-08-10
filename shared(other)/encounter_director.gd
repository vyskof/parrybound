extends Node

const BossIntroLabel := preload("res://effects/boss_intro_label.tscn")

func play_intro(boss: Node2D, boss_name: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or not is_instance_valid(boss):
		return

	if player.has_method("lock_for_intro"):
		player.lock_for_intro(2.4)

	var label := BossIntroLabel.instantiate()
	get_tree().current_scene.add_child(label)
	if label.has_method("set_boss_name"):
		label.set_boss_name(boss_name)

	var camera := player.get_node_or_null("Camera2D")
	if camera and camera.has_method("play_boss_intro"):
		await camera.play_boss_intro(boss.global_position)
