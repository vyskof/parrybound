extends Node

# ─────────────────────────────────────────────────────────────────────────────
#
#  Jak rozšiřovat:
#    • Nová data hráče   → přidej klíč do _default_player()
#    • Nová progressi    → přidej klíč do _default_progression()
#    • Nový boss         → volej GameManager.mark_boss_defeated("id_bosse")
#    • Nová mapa         → GameManager.travel_to("res://world_3.tscn")
# ─────────────────────────────────────────────────────────────────────────────

const SAVE_DIR    = "user://saves/"
const SAVE_VERSION = 1
const NUM_SLOTS   = 3

# Aktivní slot (-1 = žádný save nenačten)
var current_slot: int = -1

# Kompletní save data pro aktuální hru
var save_data: Dictionary = {}


# ─────────────────────────────────────────────────────────────────────────────
#  Inicializace
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	# Sledujeme načtení scény, abychom mohli aplikovat save data
	get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
	# Průběžně zvyšujeme play_time jen když je aktivní hra (ne v menu)
	if current_slot >= 0 and not save_data.is_empty():
		save_data["meta"]["play_time"] = save_data["meta"].get("play_time", 0.0) + delta

# ─────────────────────────────────────────────────────────────────────────────
#  Výchozí datové struktury
#  → Kdykoli přidáš novou featuru, přidej sem její výchozí hodnoty.
#    Stará uložená hra si nové klíče doplní přes _migrate_save().
# ─────────────────────────────────────────────────────────────────────────────

func _default_save(slot: int) -> Dictionary:
	return {
		"meta": {
			"version":    SAVE_VERSION,
			"slot":       slot,
			"save_time":  Time.get_datetime_string_from_system(),
			"play_time":  0.0,        # sekundy
			"area_name":  "Catacombs" # zobrazeno v menu
		},
		"world": {
			"current_scene":  "res://world.tscn",
			"spawn_point":    "default",       # jméno Node2D spawn markeru ve scéně
			"defeated_bosses": [],             # ["grim_reaper", "golem", ...]
			"unlocked_portals": [],            # pro budoucí použití
			"visited_areas":   []              # pro budoucí mapy / fast travel
		},
		"player":      _default_player(),
		"inventory":   _default_inventory(),
		"progression": _default_progression()
	}

func _default_player() -> Dictionary:
	# ── Přidávej sem nové player statistiky ──────────────────────────────────
	return {
		"health":     100,
		"max_health": 100,
		"posture":    0.0,
		"max_posture": 100.0 
		}



func _default_inventory() -> Dictionary:
	# ── Přidávej sem nové typy předmětů ──────────────────────────────────────
	return {
		"consumables": {},  # { "estus_flask": 3, "bone_dust": 1 }
		"weapons":     {},  # { "sword_01": { "level": 1 } }
		"armor":       {},  # { "hood_01": true }
		"key_items":   {}   # { "catacombs_key": true }
	}

func _default_progression() -> Dictionary:
	# ── Přidávej sem atributy, talenty, levely ───────────────────────────────
	return {
		"level":  1,
		"souls":  0,
		"attributes": {
			"vitality":   10,
			"endurance":  10,
			"strength":   10,
			"dexterity":  10
			# "intelligence": 10  ← snadno přidáš
		},
		"talents": []  # ["parry_master", "swift_roll", ...]
	}

# ─────────────────────────────────────────────────────────────────────────────
#  Nová hra / načtení hry
# ─────────────────────────────────────────────────────────────────────────────

func new_game(slot: int) -> void:
	current_slot = slot
	save_data    = _default_save(slot)
	save_to_slot()
	_change_to_scene(save_data["world"]["current_scene"])

func load_game(slot: int) -> bool:
	var data := _read_slot_file(slot)
	if data.is_empty():
		return false
	current_slot = slot
	save_data    = _migrate_save(data)  # doplní chybějící klíče z novějších verzí
	_change_to_scene(save_data["world"]["current_scene"])
	return true

# ─────────────────────────────────────────────────────────────────────────────
#  Ukládání
# ─────────────────────────────────────────────────────────────────────────────

func save_to_slot(slot: int = -1) -> void:
	if slot < 0:
		slot = current_slot
	if slot < 0:
		push_warning("GameManager: save_to_slot – žádný aktivní slot")
		return

	_capture_player_state()

	save_data["meta"]["save_time"] = Time.get_datetime_string_from_system()
	save_data["meta"]["slot"]      = slot

	var path := SAVE_DIR + "slot_%d.json" % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
	else:
		push_error("GameManager: Nelze zapsat do %s" % path)

# Získá jen metadata slotu pro zobrazení v menu (bez načítání celé hry)
func get_slot_meta(slot: int) -> Dictionary:
	var data := _read_slot_file(slot)
	return data.get("meta", {}) if not data.is_empty() else {}

func delete_slot(slot: int) -> void:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if slot == current_slot:
		current_slot = -1
		save_data = {}

# ─────────────────────────────────────────────────────────────────────────────
#  Pohyb mezi scénami
# ─────────────────────────────────────────────────────────────────────────────

func travel_to(scene_path: String, spawn_point: String = "default", should_save: bool = true) -> void:
	save_data["meta"]["area_name"] = get_area_display_name(scene_path)
	save_data["world"]["current_scene"] = scene_path
	save_data["world"]["spawn_point"]   = spawn_point
	if should_save:
		save_to_slot()
	_change_to_scene(scene_path)

func _change_to_scene(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)

# ─────────────────────────────────────────────────────────────────────────────
#  World progress
# ─────────────────────────────────────────────────────────────────────────────

func mark_boss_defeated(boss_id: String) -> void:
	var bosses: Array = save_data["world"].get("defeated_bosses", [])
	if boss_id not in bosses:
		bosses.append(boss_id)
		save_data["world"]["defeated_bosses"] = bosses

func is_boss_defeated(boss_id: String) -> bool:
	return boss_id in save_data["world"].get("defeated_bosses", [])

# ─────────────────────────────────────────────────────────────────────────────
#  Aplikace save dat na entitiy po načtení scény
# ─────────────────────────────────────────────────────────────────────────────

# Zavolej tuhle funkci z character.gd v _ready()
func apply_save_to_player(player: Node) -> void:
	if save_data.is_empty():
		return
	var p: Dictionary = save_data.get("player", {})
	if player.stats:
		player.stats.max_health = p.get("max_health", 100)
		player.stats.health     = p.get("health",     player.stats.max_health)

func _capture_player_state() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.stats:
		save_data["player"]["health"]      = player.stats.health
		save_data["player"]["max_health"]  = player.stats.max_health
		# Sem přidej další stats podle potřeby

func _on_node_added(node: Node) -> void:
	# Hráč se přidal do scény – aplikuj save data
	if node.is_in_group("player"):
		apply_save_to_player.call_deferred(node)

# ─────────────────────────────────────────────────────────────────────────────
#  Migrace starých save souborů
#  → Přidej sem logiku kdykoli změníš strukturu save dat
# ─────────────────────────────────────────────────────────────────────────────

func _migrate_save(data: Dictionary) -> Dictionary:

	# Doplní klíče které v older save chybí
	var defaults := _default_save(data.get("meta", {}).get("slot", 0))
	_deep_merge(defaults, data)

	data["meta"]["version"] = SAVE_VERSION
	return data

# Rekurzivně doplní chybějící klíče z 'defaults' do 'target'
func _deep_merge(defaults: Dictionary, target: Dictionary) -> void:
	for key in defaults:
		if not target.has(key):
			target[key] = defaults[key]
		elif target[key] is Dictionary and defaults[key] is Dictionary:
			_deep_merge(defaults[key], target[key])

# ─────────────────────────────────────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────────────────────────────────────

func _read_slot_file(slot: int) -> Dictionary:
	var path := SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text    := file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(text)
	if result == null or not result is Dictionary:
		push_warning("GameManager: Poškozený save soubor: %s" % path)
		return {}
	return result

# Formátuje sekundy na "Xh Ym" pro zobrazení v menu
func format_play_time(seconds: float) -> String:
	var total: int = maxi(0, floori(seconds))
	var h: int = int(floor(total / 3600.0))
	var m: int = int(floor((total % 3600) / 60.0))
	return "%dh %dm" % [h, m]

# Zkrácené jméno oblasti pro menu
func get_area_display_name(scene_path: String) -> String:
	var names := {
		"res://world.tscn":   "Catacombs",
		"res://world_2.tscn": "Stone Halls"
		# Přidej sem nové mapy
	}
	return names.get(scene_path, "Unknown Area")
