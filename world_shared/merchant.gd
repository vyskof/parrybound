extends Area2D

const ShopMenu := preload("res://ui/shop_menu.tscn")

@onready var label: Label = $Label

var _player_nearby: bool = false
var _menu_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.visible = false
	label.text = "[ E ] Trade"

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and not _menu_open and event.is_action_pressed("interact"):
		_open_menu()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		if not _menu_open:
			label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		label.visible = false

func _open_menu() -> void:
	_menu_open = true
	label.visible = false
	var menu := ShopMenu.instantiate()
	get_tree().root.add_child(menu)
	menu.closed.connect(_on_menu_closed)

func _on_menu_closed() -> void:
	_menu_open = false
	if _player_nearby:
		label.visible = true
