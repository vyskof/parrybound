class_name World2 extends Node2D


@export var portal_scene: PackedScene
@export var reverb_wet: float = 0.2
@export var reverb_room_size: float = 0.75
@onready var golem_boss: CharacterBody2D = $GolemBoss
@onready var portal_spawn_point: Node2D = $PortalSpawnPoint

var _reverb_effect: AudioEffectReverb
var _reverb_bus_index: int = -1

func _ready() -> void:
	_apply_arena_reverb()
	if GameManager.is_boss_defeated("golem"):
		golem_boss.queue_free()
		_spawn_portal()
		return

func _apply_arena_reverb() -> void:
	_reverb_bus_index = AudioServer.get_bus_index("Master")
	_reverb_effect = AudioEffectReverb.new()
	_reverb_effect.wet = reverb_wet
	_reverb_effect.room_size = reverb_room_size
	_reverb_effect.damping = 0.5
	AudioServer.add_bus_effect(_reverb_bus_index, _reverb_effect)

func _exit_tree() -> void:
	if is_instance_valid(_reverb_effect) and _reverb_bus_index >= 0:
		AudioBusUtil.remove_effect_safe(_reverb_bus_index, _reverb_effect)

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
	var tween := create_tween()
	tween.tween_property(portal, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
