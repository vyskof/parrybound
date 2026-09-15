extends Node2D

var current_state: State

func _ready():
	current_state = get_child(0) as State
	current_state.enter()

func change_state(state_name: String) -> void:
	var next_state := find_child(state_name) as State
	if next_state == null:
		push_error("State '%s' nenalezen" % state_name)
		return
	current_state.exit()
	current_state = next_state
	current_state.enter()
