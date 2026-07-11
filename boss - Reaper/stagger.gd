extends State

func enter() -> void:
	super.enter()
	await_and_transition("stagger", "Follow")
