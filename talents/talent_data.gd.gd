class_name TalentData

class TalentEffect:
	var id: String
	var display_name: String
	var desc: String
	var rarity: String
	var stat_key: String
	var stat_value: float

	func _init(p_id: String, p_name: String, p_desc: String, p_rarity: String, p_stat_key: String, p_stat_value: float) -> void:
		id = p_id
		display_name = p_name
		desc = p_desc
		rarity = p_rarity
		stat_key = p_stat_key
		stat_value = p_stat_value

static var _all: Dictionary = {}

static func _build() -> void:
	if not _all.is_empty():
		return
	_add("reapers_resolve", "Reaper's Resolve", "+20% stamina restored on a successful deflect", "common", "_deflect_stamina_mult", 1.2)
	_add("stone_resolve", "Stone Resolve", "-25% posture damage from hits you fail to deflect", "common", "_hit_posture_mult", 0.8)
	_add("swift_recovery", "Swift Recovery", "+30% stamina regeneration rate", "common", "_stamina_regen_mult", 1.3)
	_add("light_footed", "Light Footed", "-25% dodge stamina cost", "common", "_dodge_stamina_mult", 0.75)
	_add("patient_blade", "Patient Blade", "+0.15s counter window after a successful deflect", "rare", "_counter_window_bonus", 0.15)
	_add("momentum", "Momentum", "+15% attack damage while your deflect streak is active", "rare", "_streak_damage_mult", 1.15)
	_add("windrunner", "Windrunner", "-30% fast move cooldown", "rare", "_fast_move_cooldown_mult", 0.7)
	_add("iron_lungs", "Iron Lungs", "-60% low-stamina movement speed penalty", "legendary", "_low_stamina_penalty_mult", 0.4)

static func _add(id: String, name: String, desc: String, rarity: String, stat_key: String, stat_value: float) -> void:
	_all[id] = TalentEffect.new(id, name, desc, rarity, stat_key, stat_value)

static func get_all() -> Dictionary:
	_build()
	return _all

static func get_talent(id: String) -> TalentEffect:
	_build()
	return _all.get(id, null)

static func has_talent(id: String) -> bool:
	_build()
	return _all.has(id)
