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

var in_boss_fight: bool = false

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
			"current_scene":  "res://hub.tscn",
			"spawn_point":    "DefaultSpawn",       # jméno Node2D spawn markeru ve scéně
			"defeated_bosses": [],             # ["grim_reaper", "golem", ...]
			"seen_intros":    [],              # # ["grim_reaper", "golem", ...] — boss intro cutscéna se přehraje jen jednou
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
		"max_posture": 100.0,
		"max_stamina": 150.0
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
			"fortitude": 0,
			"tempo":     0,
			"strength":  0,
			"agility":   0
		},
		"attribute_points": 10,
		"talent_slots": 0,       
		"unlocked_talents": [],  # ["reapers_resolve", "stone_resolve", ...] — natrvalo naučené
		"equipped_talents": [], 
		"shop_purchases": {}  
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
	LoadingScreen.transition_to(path)

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

signal souls_changed(new_amount: int)
signal leveled_up(choices: Array)

func add_souls(amount: int) -> void:
	if amount <= 0 or not save_data.has("progression"):
		return
	save_data["progression"]["souls"] = get_souls() + amount
	souls_changed.emit(get_souls())

func spend_souls(amount: int) -> bool:
	if amount <= 0 or not save_data.has("progression"):
		return false
	if get_souls() < amount:
		return false
	save_data["progression"]["souls"] = get_souls() - amount
	souls_changed.emit(get_souls())
	return true

func get_souls() -> int:
	return save_data.get("progression", {}).get("souls", 0)

# Talenty a progrese

const LEVEL_UP_ATTRIBUTE_POINTS := 5
const TALENT_CHOICES_PER_LEVEL  := 4


func get_level() -> int:
	return save_data.get("progression", {}).get("level", 1)

func get_talent_slots() -> int:
	return save_data.get("progression", {}).get("talent_slots", 0)

func get_talent_def(talent_id: String) -> Dictionary:
	var effect := TalentData.get_talent(talent_id)
	if effect == null:
		return {}
	return {
		"id": effect.id,
		"name": effect.display_name,
		"desc": effect.desc,
		"rarity": effect.rarity,
	}

# Voláno po zabití bosse. Level +1, rovnou 5 attribute pointů, +1 talent slot.
# Pokud v poolu zbývá aspoň jeden nevlastněný talent, nabídne se výběr
# (až 4 náhodné) přes signál leveled_up — UI si na něj napojí popup okno
# a po výběru zavolá choose_talent().
func level_up() -> void:
	if not save_data.has("progression"):
		return
	save_data["progression"]["level"] = get_level() + 1
	add_attribute_point(LEVEL_UP_ATTRIBUTE_POINTS)
	save_data["progression"]["talent_slots"] = get_talent_slots() + 1

	var choices := _roll_talent_choices(TALENT_CHOICES_PER_LEVEL)
	if choices.is_empty():
		return
	leveled_up.emit(choices)

func _roll_talent_choices(count: int) -> Array:
	var unlocked := get_unlocked_talents()
	var available: Array = []
	for talent_id in TalentData.get_all():
		if talent_id not in unlocked:
			available.append(talent_id)
	available.shuffle()
	return available.slice(0, mini(count, available.size()))

func choose_talent(talent_id: String) -> void:
	if not TalentData.has_talent(talent_id) or not save_data.has("progression"):
		return
	var unlocked := get_unlocked_talents()
	if talent_id not in unlocked:
		unlocked.append(talent_id)
		save_data["progression"]["unlocked_talents"] = unlocked

	if get_equipped_talents().size() < get_talent_slots():
		set_talent_equipped(talent_id, true)

	save_to_slot()

	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("refresh_talents"):
		player.refresh_talents()

func get_unlocked_talents() -> Array:
	return save_data.get("progression", {}).get("unlocked_talents", [])

func get_equipped_talents() -> Array:
	return save_data.get("progression", {}).get("equipped_talents", [])

func set_talent_equipped(talent_id: String, equip: bool) -> bool:
	if not save_data.has("progression") or talent_id not in get_unlocked_talents():
		return false
	var equipped := get_equipped_talents()
	if equip:
		if talent_id in equipped:
			return true
		if equipped.size() >= get_talent_slots():
			return false
		equipped.append(talent_id)
	else:
		equipped.erase(talent_id)
	save_data["progression"]["equipped_talents"] = equipped
	return true

func add_attribute_point(amount: int = 1) -> void:
	if not save_data.has("progression"):
		return
	save_data["progression"]["attribute_points"] = get_attribute_points() + amount

func get_attribute_points() -> int:
	return save_data.get("progression", {}).get("attribute_points", 0)

func spend_attribute_point() -> bool:
	if get_attribute_points() <= 0:
		return false
	save_data["progression"]["attribute_points"] = get_attribute_points() - 1
	return true

func get_attribute_level(attr_name: String) -> int:
	return save_data.get("progression", {}).get("attributes", {}).get(attr_name, 10)

func increase_attribute(attr_name: String) -> void:
	if not save_data.has("progression"):
		return
	var attrs: Dictionary = save_data["progression"].get("attributes", {})
	attrs[attr_name] = attrs.get(attr_name, 0) + 1
	save_data["progression"]["attributes"] = attrs


func mark_intro_seen(boss_id: String) -> void:
	if not save_data.has("world"):
		return
	var seen: Array = save_data["world"].get("seen_intros", [])
	if boss_id not in seen:
		seen.append(boss_id)
		save_data["world"]["seen_intros"] = seen

func get_shop_purchase_count(item_id: String) -> int:
	return save_data.get("progression", {}).get("shop_purchases", {}).get(item_id, 0)

func record_shop_purchase(item_id: String) -> void:
	if not save_data.has("progression"):
		return
	var purchases: Dictionary = save_data["progression"].get("shop_purchases", {})
	purchases[item_id] = purchases.get(item_id, 0) + 1
	save_data["progression"]["shop_purchases"] = purchases


func has_seen_intro(boss_id: String) -> bool:
	if not save_data.has("world"):
		return false
	return boss_id in save_data["world"].get("seen_intros", [])

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
		player.stats.max_posture = p.get("max_posture", 100.0)  
		player.stats.max_stamina = p.get("max_stamina", 150.0) 


func _capture_player_state() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.stats:
		save_data["player"]["health"]      = player.stats.health
		save_data["player"]["max_health"]  = player.stats.max_health
		save_data["player"]["posture"]     = player.stats.posture  
		save_data["player"]["max_posture"] = player.stats.max_posture
		save_data["player"]["max_stamina"] = player.stats.max_stamina

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

	_rename_legacy_attribute_keys(data)

	data["meta"]["version"] = SAVE_VERSION
	return data

# Staré save soubory měly atributy pojmenované vitality/endurance/dexterity —
# přejmenováno na fortitude/tempo/agility. Tahle funkce převede staré klíče
# na nové, aby hráč nepřišel o body, co už do nich investoval.
func _rename_legacy_attribute_keys(data: Dictionary) -> void:
	if not data.has("progression"):
		return
	var attrs: Dictionary = data["progression"].get("attributes", {})
	var renames := {
		"vitality": "fortitude",
		"endurance": "tempo",
		"dexterity": "agility",
	}
	for old_key in renames:
		if attrs.has(old_key):
			var new_key: String = renames[old_key]
			if not attrs.has(new_key) or attrs[new_key] == 10:
				attrs[new_key] = attrs[old_key]
			attrs.erase(old_key)
	data["progression"]["attributes"] = attrs

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
		"res://world_2.tscn": "Stone Halls",
		"res://hub.tscn":     "Sanctuary"
		# Přidej sem nové mapy
	}
	return names.get(scene_path, "Unknown Area")

func get_current_spawn_point() -> String:
	return save_data.get("world", {}).get("spawn_point", "DefaultSpawn")
	
