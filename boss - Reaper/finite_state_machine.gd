extends Node2D

var current_state: State

func _ready():
	current_state = get_child(0) as State
	current_state.enter()

func change_state(state_name: String) -> void:
	current_state.exit()
	current_state = find_child(state_name) as State
	current_state.enter()
