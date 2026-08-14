

class_name World1 extends Node2D

@export var portal_scene: PackedScene
@onready var portal_spawn_point: Node2D = $PortalSpawnPoint
@onready var grim_boss: CharacterBody2D = $GrimBoss


func _ready() -> void:
	if GameManager.is_boss_defeated("grim_reaper"):
		grim_boss.queue_free()
		_spawn_portal()
		return

func _on_boss_encounter_started() -> void:
	_set_fog_walls_active(true)

func _on_boss_defeated(_boss_id: String) -> void:
	_set_fog_walls_active(false)
	call_deferred("_spawn_portal")

func _set_fog_walls_active(active: bool) -> void:
	for fog in get_tree().get_nodes_in_group("fog_wall"):
		if active and fog.has_method("activate"):
			fog.activate()
		elif not active and fog.has_method("deactivate"):
			fog.deactivate()

func _spawn_portal() -> void:
	if portal_scene == null:
		return
	var portal := portal_scene.instantiate()
	add_child(portal)
	portal.global_position = portal_spawn_point.global_position
	portal.scale = Vector2.ZERO
	create_tween().tween_property(portal, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
