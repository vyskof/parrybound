class_name ShopMenu extends CanvasLayer

signal closed

const SHOP_ITEMS := [
	{"id": "vigor_shard", "name": "Vigor Shard", "desc": "+10 Max Health", "base_cost": 100, "cost_growth": 0.6, "max_purchases": 5},
	{"id": "focus_shard", "name": "Focus Shard", "desc": "+10 Max Stamina", "base_cost": 80, "cost_growth": 0.6, "max_purchases": 5},
]

@onready var _list: VBoxContainer = $VBoxContainer/ItemList
@onready var _souls_label: Label = $VBoxContainer/SoulsLabel
@onready var _close_button: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_close_button.pressed.connect(_on_close_pressed)
	_rebuild_list()

func _rebuild_list() -> void:
	for child in _list.get_children():
		child.queue_free()

	_souls_label.text = "Souls: %d" % GameManager.get_souls()

	for item in SHOP_ITEMS:
		var purchases := GameManager.get_shop_purchase_count(item.id)
		var maxed = purchases >= item.max_purchases
		var cost := _cost_for(item, purchases)

		var row := HBoxContainer.new()

		var info := Label.new()
		info.text = "%s (%s) — %d souls%s" % [item.name, item.desc, cost, "  [MAX]" if maxed else ""]
		row.add_child(info)

		var buy_button := Button.new()
		buy_button.text = "Buy"
		buy_button.disabled = maxed or GameManager.get_souls() < cost
		buy_button.pressed.connect(_on_buy_pressed.bind(item))
		row.add_child(buy_button)

		_list.add_child(row)

func _cost_for(item: Dictionary, purchases: int) -> int:
	return int(item.base_cost * (1.0 + purchases * item.cost_growth))

func _on_buy_pressed(item: Dictionary) -> void:
	var purchases := GameManager.get_shop_purchase_count(item.id)
	if purchases >= item.max_purchases:
		return
	var cost := _cost_for(item, purchases)
	if not GameManager.spend_souls(cost):
		return

	GameManager.record_shop_purchase(item.id)
	_apply_item_effect(item.id)
	GameManager.save_to_slot()
	_rebuild_list()

func _apply_item_effect(item_id: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player or not player.stats:
		return
	match item_id:
		"vigor_shard":
			player.stats.max_health += 10.0
			player.stats.health += 10.0
		"focus_shard":
			player.stats.max_stamina += 10.0
			player.stats.stamina += 10.0

func _on_close_pressed() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
