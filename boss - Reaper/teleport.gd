extends State

func enter() -> void:
	super.enter()
	await_and_transition("skill", "Attack")

func teleport() -> void:
	var angle: float = randf() * TAU
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * 50
	owner.position = character.position + offset
