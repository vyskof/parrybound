class_name World2 extends Node2D


@export var portal_scene: PackedScene
@onready var golem_boss: CharacterBody2D = $GolemBoss
@onready var portal_spawn_point: Node2D = $PortalSpawnPoint

func _ready() -> void:
	if GameManager.is_boss_defeated("golem"):
		golem_boss.queue_free()
		_spawn_portal()
		return

func _on_boss_defeated(_boss_id: String) -> void:
	call_deferred("_spawn_portal")

func _spawn_portal() -> void:
	if portal_scene == null:
		return

	var portal := portal_scene.instantiate()
	add_child(portal)
	portal.global_position = portal_spawn_point.global_position

	portal.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(portal, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
