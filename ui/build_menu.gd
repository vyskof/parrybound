class_name BuildMenu extends CanvasLayer

signal closed

const ATTRIBUTE_NAMES := ["fortitude", "tempo", "strength", "agility"]
const ATTRIBUTE_LABELS := {
	"fortitude": "Fortitude (+8 Max HP)",
	"tempo":     "Tempo (+8 Max Stamina)",
	"strength":  "Strength (+8% Attack Dmg)",
	"agility":   "Agility (+1 Stamina Regen/s)",
}

@onready var _points_label: Label = $VBoxContainer/PointsLabel
@onready var _attr_list: VBoxContainer = $VBoxContainer/AttributeList
@onready var _talent_list: VBoxContainer = $VBoxContainer/TalentList
@onready var _close_button: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_close_button.pressed.connect(_on_close_pressed)
	_rebuild()

func _rebuild() -> void:
	for child in _attr_list.get_children():
		child.queue_free()
	for child in _talent_list.get_children():
		child.queue_free()

	_points_label.text = "Attribute Points: %d   |   Talent Slots: %d / %d" % [
		GameManager.get_attribute_points(),
		GameManager.get_equipped_talents().size(),
		GameManager.get_talent_slots(),
	]

	for attr in ATTRIBUTE_NAMES:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s — Lv %d" % [ATTRIBUTE_LABELS[attr], GameManager.get_attribute_level(attr)]
		row.add_child(label)
		var btn := Button.new()
		btn.text = "+1"
		btn.disabled = GameManager.get_attribute_points() <= 0
		btn.pressed.connect(_on_increase_attribute.bind(attr))
		row.add_child(btn)
		_attr_list.add_child(row)

	for talent_id in GameManager.get_unlocked_talents():
		var def := GameManager.get_talent_def(talent_id)
		if def.is_empty():
			continue
		var row := HBoxContainer.new()
		var equipped = talent_id in GameManager.get_equipped_talents()
		var label := Label.new()
		label.text = "%s — %s%s" % [def.name, def.desc, "  [EQUIPPED]" if equipped else ""]
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Unequip" if equipped else "Equip"
		btn.pressed.connect(_on_toggle_talent.bind(talent_id, not equipped))
		row.add_child(btn)
		_talent_list.add_child(row)


func _on_increase_attribute(attr_name: String) -> void:
	if not GameManager.spend_attribute_point():
		return
	GameManager.increase_attribute(attr_name)
	_apply_attribute_to_player(attr_name)
	GameManager.save_to_slot()
	_rebuild()

func _apply_attribute_to_player(attr_name: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player or not player.stats:
		return
	match attr_name:
		"fortitude":
			player.stats.max_health += 8.0
			player.stats.health += 8.0
			if player.has_method("refresh_max_value_bars"):
				player.refresh_max_value_bars()
		"tempo":
			player.stats.max_stamina += 8.0
			player.stats.stamina += 8.0
			if player.has_method("refresh_max_value_bars"):
				player.refresh_max_value_bars()
		"strength", "agility":
			if player.has_method("refresh_attribute_bonuses"):
				player.refresh_attribute_bonuses()

func _on_toggle_talent(talent_id: String, equip: bool) -> void:
	if not GameManager.set_talent_equipped(talent_id, equip):
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_talents"):
		player.refresh_talents()
	GameManager.save_to_slot()
	_rebuild()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
