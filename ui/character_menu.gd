class_name CharacterMenu extends CanvasLayer

signal closed

@onready var _stats_list:  VBoxContainer = $VBoxContainer/StatsList
@onready var _attr_list:   VBoxContainer = $VBoxContainer/AttributeList
@onready var _talent_list: VBoxContainer = $VBoxContainer/TalentList
@onready var _close_button: Button        = $VBoxContainer/CloseButton

var _player: Character

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_close_button.pressed.connect(_on_close_pressed)

func setup(player: Character) -> void:
	_player = player
	_rebuild()

func _rebuild() -> void:
	for child in _stats_list.get_children():
		child.queue_free()
	for child in _attr_list.get_children():
		child.queue_free()
	for child in _talent_list.get_children():
		child.queue_free()

	if not _player or not _player.stats:
		return

	_add_row(_stats_list, "Health",  "%d / %d" % [roundi(_player.stats.health), roundi(_player.stats.max_health)])
	_add_row(_stats_list, "Stamina", "%d / %d" % [roundi(_player.stats.stamina), roundi(_player.stats.max_stamina)])
	_add_row(_stats_list, "Posture", "%d / %d" % [roundi(_player.stats.posture), roundi(_player.stats.max_posture)])
	_add_row(_stats_list, "Attack Damage", "%d" % roundi(_player.get_current_attack_damage()))
	_add_row(_stats_list, "Level", "%d" % GameManager.get_level())
	_add_row(_stats_list, "Souls", "%d" % GameManager.get_souls())

	for attr_name in ["strength", "fortitude", "agility", "tempo"]:
		_add_row(_attr_list, attr_name.capitalize(), "%d" % GameManager.get_attribute_level(attr_name))

	var equipped := GameManager.get_equipped_talents()
	if equipped.is_empty():
		_add_row(_talent_list, "—", "No talents equipped")
	for talent_id in equipped:
		var def := GameManager.get_talent_def(talent_id)
		if def.is_empty():
			continue
		_add_row(_talent_list, def.name, def.desc)

func _add_row(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(value)
	parent.add_child(row)

func _on_close_pressed() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
