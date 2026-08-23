extends State

@export var minion_node: PackedScene

func enter() -> void:
	super.enter()
	await_and_transition("summon", "Follow")

func spawn() -> void:
	if not minion_node:
		push_warning("SpawnMinion: minion_node není nastavený, přeskočeno.")
		return
	var minion: Node = minion_node.instantiate()
	minion.position = owner.position + Vector2(40, -40)
	get_tree().current_scene.add_child(minion)
