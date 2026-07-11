extends State

func enter() -> void:
	super.enter()
	await_and_transition("armor_buff", "Follow")
