extends State

@export var bullet_node: PackedScene

func enter() -> void:
	super.enter()
	animation_player.play("ranged_attack")
	await animation_player.animation_finished
	_shoot()
	get_parent().change_state("Dash")

func _shoot() -> void:
	var bullet: Node = bullet_node.instantiate()
	bullet.position = owner.position
	get_tree().current_scene.add_child(bullet)
