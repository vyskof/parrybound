class_name CharacterMenu extends CanvasLayer

signal closed

const FONT_SIZE_TITLE := 8
const FONT_SIZE_ROW    := 6

var _player: Character
var _panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_panel = PanelContainer.new()
	_panel.anchor_left   = 0.0
	_panel.anchor_top    = 0.0
	_panel.anchor_right  = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left   = 30
	_panel.offset_top    = 20
	_panel.offset_right  = -30
	_panel.offset_bottom = -20
	add_child(_panel)

func setup(player: Character) -> void:
	_player = player
	_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_menu") or event.is_action_pressed("ui_cancel"):
		_on_close_pressed()

func _rebuild() -> void:
	for child in _panel.get_children():
		child.queue_free()
	if not _player or not _player.stats:
		return

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	_panel.add_child(outer)

	var title := Label.new()
	title.text = "Character"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	outer.add_child(title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	outer.add_child(columns)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 1)
	columns.add_child(left)

	_add_row(left, "Health",  "%d / %d" % [roundi(_player.stats.health), roundi(_player.stats.max_health)])
	_add_row(left, "Stamina", "%d / %d" % [roundi(_player.stats.stamina), roundi(_player.stats.max_stamina)])
	_add_row(left, "Posture", "%d / %d" % [roundi(_player.stats.posture), roundi(_player.stats.max_posture)])
	_add_row(left, "Attack Dmg", "%d" % roundi(_player.get_current_attack_damage()))
	_add_row(left, "Level", "%d" % GameManager.get_level())
	_add_row(left, "Souls", "%d" % GameManager.get_souls())

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 1)
	columns.add_child(right)

	for attr_name in ["strength", "fortitude", "agility", "tempo"]:
		_add_row(right, attr_name.capitalize(), "%d" % GameManager.get_attribute_level(attr_name))

	var talent_title := Label.new()
	talent_title.text = "Talents:"
	talent_title.add_theme_font_size_override("font_size", FONT_SIZE_ROW)
	right.add_child(talent_title)

	var equipped := GameManager.get_equipped_talents()
	if equipped.is_empty():
		var none_label := Label.new()
		none_label.text = "None equipped"
		none_label.add_theme_font_size_override("font_size", FONT_SIZE_ROW)
		right.add_child(none_label)
	for talent_id in equipped:
		var def := GameManager.get_talent_def(talent_id)
		if def.is_empty():
			continue
		var t_label := Label.new()
		t_label.text = def.name
		t_label.add_theme_font_size_override("font_size", FONT_SIZE_ROW)
		right.add_child(t_label)

	var close_button := Button.new()
	close_button.text = "Close (Tab)"
	close_button.add_theme_font_size_override("font_size", FONT_SIZE_ROW)
	close_button.pressed.connect(_on_close_pressed)
	outer.add_child(close_button)

func _add_row(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60, 0)
	label.add_theme_font_size_override("font_size", FONT_SIZE_ROW)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", FONT_SIZE_ROW)
	row.add_child(value)
	parent.add_child(row)

func _on_close_pressed() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()
