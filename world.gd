extends Node2D

@export var portal_scene: PackedScene
@onready var portal_spawn_point: Node2D = $PortalSpawnPoint
@onready var grim_boss: CharacterBody2D = $GrimBoss


func _on_boss_defeated(_boss_id: String) -> void:
	call_deferred("_spawn_portal")

func _ready() -> void:
	if GameManager.is_boss_defeated("grim_reaper"):
		grim_boss.queue_free()
		_spawn_portal()
		return

	if grim_boss and not grim_boss.boss_defeated.is_connected(_on_boss_defeated):
		grim_boss.boss_defeated.connect(_on_boss_defeated)

func _spawn_portal() -> void:
	if portal_scene == null:
		return

	var portal := portal_scene.instantiate()
	add_child(portal)
	portal.global_position = portal_spawn_point.global_position

	portal.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(portal, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
