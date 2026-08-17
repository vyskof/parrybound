class_name MainMenu extends Control

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var slots_container: VBoxContainer = $SlotsContainer
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D



var _slot_metas: Array[Dictionary] = []


func _ready() -> void:
	_connect_slot_buttons()
	_refresh_slots()
	_update_continue_button()

	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	audio_stream_player_2d.play()

# ─────────────────────────────────────────────────────────────────────────────
#  Zobrazení slotů
# ─────────────────────────────────────────────────────────────────────────────

func _connect_slot_buttons() -> void:
	for i in GameManager.NUM_SLOTS:
		var slot_node := slots_container.get_node("Slot%d" % (i + 1))
		slot_node.get_node("Hbox/LoadButton").pressed.connect(_on_load_slot.bind(i))
		slot_node.get_node("Hbox/NewGameButton").pressed.connect(_on_new_game_in_slot.bind(i))
		slot_node.get_node("Hbox/DeleteButton").pressed.connect(_on_delete_slot.bind(i))



func _refresh_slots() -> void:
	_slot_metas.clear()
	for i in GameManager.NUM_SLOTS:
		var meta: Dictionary = GameManager.get_slot_meta(i)
		_slot_metas.append(meta)
		_update_slot_ui(i, meta)

func _update_slot_ui(slot: int, meta: Dictionary) -> void:
	var slot_node := slots_container.get_node("Slot%d" % (slot + 1))
	var info_label: Label   = slot_node.get_node("Hbox/InfoLabel")
	var load_btn:   Button  = slot_node.get_node("Hbox/LoadButton")
	var new_btn:    Button  = slot_node.get_node("Hbox/NewGameButton")
	var delete_btn: Button  = slot_node.get_node("Hbox/DeleteButton")


	if meta.is_empty():
		info_label.text    = "Slot %d  —  Empty" % (slot + 1)
		load_btn.visible   = false
		delete_btn.visible = false
		new_btn.visible    = true
	else:
		var area: String   = meta.get("area_name", "Unknown")
		var play_time: String = GameManager.format_play_time(
	float(meta.get("play_time", 0.0))
	)
		info_label.text    = "Slot %d  ·  %s  ·  %s" % [slot + 1, area, play_time]
		load_btn.visible   = true
		delete_btn.visible = true
		new_btn.visible    = false


# ─────────────────────────────────────────────────────────────────────────────
#  Continue – nejnovější save
# ─────────────────────────────────────────────────────────────────────────────

func _update_continue_button() -> void:
	continue_button.visible = _get_latest_slot() >= 0

func _get_latest_slot() -> int:
	var best_slot   := -1
	var best_time   := ""
	for i in GameManager.NUM_SLOTS:
		var meta := _slot_metas[i] if i < _slot_metas.size() else {}
		if meta.is_empty():
			continue
		var t: String = meta.get("save_time", "")
		if t > best_time:  # ISO-8601 string porovnání funguje správně
			best_time = t
			best_slot = i
	return best_slot

# ─────────────────────────────────────────────────────────────────────────────
#  Handlery
# ─────────────────────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	var slot := _get_latest_slot()
	if slot >= 0:
		GameManager.load_game(slot)

func _on_new_game_pressed() -> void:
	# Najdi první prázdný slot, jinak dej hráči na výběr
	for i in GameManager.NUM_SLOTS:
		if _slot_metas[i].is_empty():
			GameManager.new_game(i)
			return
	push_warning("Všechny save sloty jsou obsazené. Vyber slot ručně.")

func _on_new_game_in_slot(slot: int) -> void:
	GameManager.new_game(slot)

func _on_load_slot(slot: int) -> void:
	GameManager.load_game(slot)

func _on_delete_slot(slot: int) -> void:
	# Přidej potvrzovací dialog dle potřeby
	GameManager.delete_slot(slot)
	_refresh_slots()
	_update_continue_button()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
