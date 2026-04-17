extends State

@onready var collision = owner.get_node("PlayerDetection/CollisionShape2D")
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../../PlayerDetection/AudioStreamPlayer2D"
@onready var texture_progress_bar = owner.get_node("UI/TextureProgressBar")
@onready var texture_posture_bar = owner.get_node("UI/TexturePostureBar")



var character_entered: bool = false:
	set(value):
		character_entered = value
		collision.set_deferred("disabled", value)
		texture_progress_bar.set_deferred("visible", value)
		texture_posture_bar.set_deferred("visible", value)



func _on_player_detection_body_entered(_body: Node2D) -> void:
	character_entered = true 
	audio_stream_player_2d.play()

func transition():
	if character_entered:
		get_parent().change_state("Follow")
