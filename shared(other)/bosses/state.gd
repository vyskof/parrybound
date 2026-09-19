class_name State extends Node2D

var is_active: bool = false

@onready var character = get_tree().get_first_node_in_group("player")
@onready var animation_player = owner.get_node("AnimationPlayer")

func await_animation(anim_name: String) -> void:
	animation_player.play(anim_name)
	await animation_player.animation_finished

func await_and_transition(anim_name: String, next_state: String) -> void:
	await await_animation(anim_name)
	if is_active:
		get_parent().change_state(next_state)

func _ready() -> void:
	set_physics_process(false)

func enter() -> void:
	is_active = true
	set_physics_process(true)

func exit() -> void:
	is_active = false
	set_physics_process(false)

func transition() -> void:
	pass

func _physics_process(_delta):
	transition()
