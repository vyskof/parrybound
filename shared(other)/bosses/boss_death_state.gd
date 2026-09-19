class_name BossDeathState extends State


@onready var _music: AudioStreamPlayer2D = owner.get_node_or_null("PlayerDetection/AudioStreamPlayer2D")


func enter() -> void:
	super.enter()
	owner.set_physics_process(false)
	animation_player.play("death")
	if _music:
		_music.stop()


func boss_slained() -> void:
	animation_player.play("boss_slained")
