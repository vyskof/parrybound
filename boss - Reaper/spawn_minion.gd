extends State

@export var minion_node: PackedScene

func enter() -> void:
	super.enter()
	await_and_transition("summon", "Follow")

func spawn() -> void:
	var minion: Node = minion_node.instantiate()
	minion.position = owner.position + Vector2(40, -40)
	get_tree().current_scene.add_child(minion) 
