extends State

var can_transition: bool = false


@onready var _visual: Node2D = owner.find_child("*Sprite2D", true, false)

func enter():
	super.enter()
	can_transition = false
	owner.set_physics_process(false)   
	owner.is_vulnerable = true         
	_play_knockdown_squash()
	animation_player.play("stagger")
	await animation_player.animation_finished
	can_transition = true

func exit():
	super.exit()
	owner.is_vulnerable = false

func _play_knockdown_squash() -> void:
	VisualFX.squash_stretch(_visual)
func transition():
	if can_transition:
		get_parent().change_state("Follow")
		can_transition = false
