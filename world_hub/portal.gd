extends Area2D

@export var destination_scene: String
@export var destination_spawn: String

@onready var label: Label = $Label
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_nearby: bool = false
var _used: bool = false  

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.visible = false
	label.text    = "[ E ] Enter"

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and not _used:
		if event.is_action_pressed("interact"):
			_enter_portal()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		label.visible  = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		label.visible  = false

func _enter_portal() -> void:
	_used = true
	label.visible = false

	var tween := create_tween()
	tween.tween_property(get_tree().current_scene, "modulate", Color(0, 0, 0, 1), 0.4)
	await tween.finished
	
	GameManager.travel_to(destination_scene, destination_spawn)
