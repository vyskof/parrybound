class_name HubWorld extends Node2D

@onready var character: CharacterBody2D = $character
@export var reverb_wet: float = 0.12
@export var reverb_room_size: float = 0.45

var _reverb_effect: AudioEffectReverb
var _reverb_bus_index: int = -1

func _ready() -> void:
	_apply_arena_reverb()
	SpawnPointUtil.apply(character, self, GameManager.get_current_spawn_point())

func _apply_arena_reverb() -> void:
	_reverb_bus_index = AudioServer.get_bus_index("Master")
	_reverb_effect = AudioEffectReverb.new()
	_reverb_effect.wet = reverb_wet
	_reverb_effect.room_size = reverb_room_size
	_reverb_effect.damping = 0.6
	AudioServer.add_bus_effect(_reverb_bus_index, _reverb_effect)
	

func _exit_tree() -> void:
	if is_instance_valid(_reverb_effect) and _reverb_bus_index >= 0:
		AudioBusUtil.remove_effect_safe(_reverb_bus_index, _reverb_effect)
		
