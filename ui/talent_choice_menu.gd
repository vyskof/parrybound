class_name TalentChoiceMenu extends CanvasLayer

signal closed

@onready var _title: Label        = $VBoxContainer/TitleLabel
@onready var _list: VBoxContainer = $VBoxContainer/ChoiceList

var _choice_ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_title.text = "Level Up! (Level %d)" % GameManager.get_level()

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
		var btn := Button.new()
		btn.text = "[%s] %s\n%s" % [def.rarity.capitalize(), def.name, def.desc]
		btn.modulate = _rarity_color(def.rarity)
		btn.pressed.connect(_on_talent_picked.bind(talent_id))
		_list.add_child(btn)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":      return Color(0.45, 0.7, 1.0)
		"legendary": return Color(1.0, 0.75, 0.2)
		_:           return Color(0.9, 0.9, 0.9)

func _on_talent_picked(talent_id: String) -> void:
	GameManager.choose_talent(talent_id)
	get_tree().paused = false
	closed.emit()
	queue_free()
