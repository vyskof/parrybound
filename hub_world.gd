class_name HubWorld extends Node2D

@onready var character: CharacterBody2D = $character

func _ready() -> void:
	SpawnPointUtil.apply(character, self, GameManager.get_current_spawn_point())
