class_name BossIdleState extends State

@onready var _detection: CollisionShape2D = owner.get_node("PlayerDetection/CollisionShape2D")
@onready var _music: AudioStreamPlayer2D  = owner.get_node_or_null("PlayerDetection/AudioStreamPlayer2D")
@onready var _health_bar: Node            = owner.get_node_or_null("UI/TextureProgressBar")
@onready var _posture_bar: Node           = owner.get_node_or_null("UI/TexturePostureBar")

var _boss_active: bool = false

var encounter_started: bool = false:
	set(value):
		encounter_started = value
		_detection.set_deferred("disabled", value)
		if _health_bar:
			_health_bar.set_deferred("visible", value)
		if _posture_bar:
			_posture_bar.set_deferred("visible", value)


func _on_player_detection_body_entered(body: Node2D) -> void:
	if encounter_started or not body.is_in_group("player"):
		return
	encounter_started = true
	if _music:
		_music.play()
	owner.encounter_started.emit()
	_play_intro()


func _play_intro() -> void:
	await EncounterDirector.play_intro(owner, owner.display_name, owner.boss_id)
	_boss_active = true


func transition() -> void:
	if _boss_active:
		get_parent().change_state("Follow")
