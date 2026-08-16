class_name CampfireMenu extends CanvasLayer

signal closed

const BuildMenuScene := preload("res://ui/build_menu.tscn")

@onready var _main_options: VBoxContainer = $VBoxContainer
@onready var _travel_list: VBoxContainer = $TravelList
@onready var _rest_button: Button = $VBoxContainer/RestButton
@onready var _travel_button: Button = $VBoxContainer/TravelButton
@onready var _build_button: Button = $VBoxContainer/BuildButton
@onready var _cancel_button: Button = $VBoxContainer/CancelButton
@onready var _world1_button: Button = $TravelList/World1Button
@onready var _world2_button: Button = $TravelList/World2Button
@onready var _back_button: Button = $TravelList/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_travel_list.visible = false

	_rest_button.pressed.connect(_on_rest_pressed)
	_travel_button.pressed.connect(_on_travel_pressed)
	_build_button.pressed.connect(_on_build_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_world1_button.pressed.connect(_on_travel_to.bind("res://world.tscn"))
	_world2_button.pressed.connect(_on_travel_to.bind("res://world_2.tscn"))
	_back_button.pressed.connect(_on_travel_back_pressed)

func _on_build_pressed() -> void:
	var menu := BuildMenuScene.instantiate()
	get_tree().root.add_child(menu)

func _on_rest_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.stats:
		player.stats.health  = player.stats.max_health
		player.stats.stamina = player.stats.max_stamina
		player.stats.posture = 0.0
	GameManager.save_to_slot()
	_close()

func _on_travel_pressed() -> void:
	_main_options.visible = false
	_travel_list.visible = true

func _on_travel_back_pressed() -> void:
	_travel_list.visible = false
	_main_options.visible = true

func _on_travel_to(scene_path: String) -> void:
	GameManager.travel_to(scene_path, _spawn_for(scene_path))
	get_tree().paused = false
	queue_free()

func _spawn_for(scene_path: String) -> String:
	match scene_path:
		"res://world.tscn":
			return "FromHubSpawn"
		"res://world_2.tscn":
			return "PlayerSpawn"
	return "DefaultSpawn"

func _on_cancel_pressed() -> void:
	_close()

func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
