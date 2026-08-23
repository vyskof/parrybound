class_name TalentChoiceMenu extends CanvasLayer

signal closed

const CARD_MIN_SIZE := Vector2(90, 130)

@onready var _title: Label        = $VBoxContainer/TitleLabel
@onready var _list: HBoxContainer = $VBoxContainer/ChoiceList

var _choice_ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_title.text = "Level Up! (Level %d)" % GameManager.get_level()
	_play_entrance_animation()

func setup(choice_ids: Array) -> void:
	_choice_ids = choice_ids
	_rebuild()

func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for talent_id in _choice_ids:
		var def := GameManager.get_talent_def(talent_id)
		if def.is_empty():
			continue
		_list.add_child(_build_card(talent_id, def))

func _build_card(talent_id: String, def: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_MIN_SIZE

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var rarity_label := Label.new()
	rarity_label.text = def.rarity.capitalize()
	rarity_label.modulate = _rarity_color(def.rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_label)

	var name_label := Label.new()
	name_label.text = def.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = def.desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(CARD_MIN_SIZE.x - 10, 0)
	vbox.add_child(desc_label)

	var btn := Button.new()
	btn.text = "Choose"
	btn.pressed.connect(_on_talent_picked.bind(talent_id))
	vbox.add_child(btn)

	return panel

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":      return Color(0.45, 0.7, 1.0)
		"legendary": return Color(1.0, 0.75, 0.2)
		_:           return Color(0.9, 0.9, 0.9)

func _play_entrance_animation() -> void:
	var container := $VBoxContainer
	container.modulate.a = 0.0
	container.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(container, "scale", Vector2.ONE, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_talent_picked(talent_id: String) -> void:
	GameManager.choose_talent(talent_id)
	get_tree().paused = false
	closed.emit()
	queue_free()
