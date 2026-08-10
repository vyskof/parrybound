extends Node

const BossIntroLabel := preload("res://effects/boss_intro_label.tscn")
const SKIP_ACTIONS := ["attack", "parry", "dodge"]

func play_intro(boss: Node2D, boss_name: String, boss_id: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or not is_instance_valid(boss):
		return

	if GameManager.has_seen_intro(boss_id):
		return   # už viděno — boss se aktivuje okamžitě, žádná cutscéna

	GameManager.mark_intro_seen(boss_id)

	if player.has_method("lock_for_intro"):
		player.lock_for_intro(2.4)

	var label := BossIntroLabel.instantiate()
	get_tree().current_scene.add_child(label)
	if label.has_method("set_boss_name"):
		label.set_boss_name(boss_name)

	var camera := player.get_node_or_null("Camera2D")
	if not camera or not camera.has_method("build_boss_intro_tween"):
		return

	var tween: Tween = camera.build_boss_intro_tween(boss.global_position)

	while is_instance_valid(tween) and tween.is_valid() and tween.is_running():
		if _skip_requested():
			camera.skip_boss_intro(tween)
			if is_instance_valid(label) and label.has_method("skip"):
				label.skip()
			if player.has_method("skip_intro_lock"):
				player.skip_intro_lock()
			return
		await get_tree().process_frame

func _skip_requested() -> bool:
	for action in SKIP_ACTIONS:
		if Input.is_action_just_pressed(action):
			return true
	return false
