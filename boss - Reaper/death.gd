extends State

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../../PlayerDetection/AudioStreamPlayer2D"


func enter():
	super.enter()
	animation_player.play("death")
	audio_stream_player_2d.stop()

func boss_slained():
	animation_player.play("boss_slained")
