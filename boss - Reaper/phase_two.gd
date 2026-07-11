extends State

func enter() -> void:
	super.enter()
	await_and_transition("phase_2", "Follow")
