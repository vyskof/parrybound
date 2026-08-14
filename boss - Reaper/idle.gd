extends State

@onready var collision = owner.get_node("PlayerDetection/CollisionShape2D")
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../../PlayerDetection/AudioStreamPlayer2D"
@onready var texture_progress_bar = owner.get_node("UI/TextureProgressBar")
@onready var texture_posture_bar = owner.get_node("UI/TexturePostureBar")



const BOSS_DISPLAY_NAME := "Grim Reaper"

var character_entered: bool = false:
	set(value):
		character_entered = value
		collision.set_deferred("disabled", value)
		texture_progress_bar.set_deferred("visible", value)
		texture_posture_bar.set_deferred("visible", value)

var _boss_active: bool = false


func _on_player_detection_body_entered(_body: Node2D) -> void:
	character_entered = true 
	audio_stream_player_2d.play()
	owner.emit_signal("encounter_started")
	_play_intro()

func _play_intro() -> void:
	await EncounterDirector.play_intro(owner, BOSS_DISPLAY_NAME, owner.boss_id)
	_boss_active = true

func transition():
	if _boss_active:
		get_parent().change_state("Follow")
