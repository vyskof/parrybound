class_name ParryResolver extends Node

enum Result {
	NONE,      ## Žádný aktivní parry pokus (výchozí stav)
	PERFECT,   ## Timing v úzkém okně → velká odměna
	GUARD,     ## Pozdní parry → malá odměna + chip damage hráči
	WHIFF      ## Parry bez příchozího útoku → penalizace
}

@export var base_perfect_window: float  = 0.14
@export var guard_window: float         = 0.28
@export var spam_decay_time: float      = 2.0
@export var whiff_cooldown: float       = 0.55

signal resolved(result: Result, combat_data: CombatData)

var _is_active: bool   = false
var _timer: float      = 0.0
var _spam_count: int   = 0
var _spam_decay_timer: float = 0.0
var _in_cooldown: bool = false

var _current_perfect_window: float:
	get: 
		match _spam_count:
			0, 1: return base_perfect_window
			2:    return base_perfect_window * 0.5
			_:    return 0.0

func try_start() -> bool:
	if _in_cooldown or _is_active:
		return false
	_is_active = true
	_timer     = 0.0
	_spam_decay_timer = 0.0
	return true

func tick(delta: float) -> void:
	if not _is_active and _spam_count > 0:
		_spam_decay_timer += delta
		if _spam_decay_timer >= spam_decay_time:
			_spam_count       = 0
			_spam_decay_timer = 0.0
	if not _is_active:
		return
	_timer += delta
	if _timer >= guard_window:
		_resolve(Result.WHIFF, null)

func evaluate(combat_data: CombatData) -> Result:
	if not _is_active:
		return Result.NONE
	var result := Result.GUARD if _timer > _current_perfect_window else Result.PERFECT
	_resolve(result, combat_data)
	return result

func is_active() -> bool:
	return _is_active

func is_in_cooldown() -> bool:
	return _in_cooldown

func get_spam_count() -> int:
	return _spam_count

func reset_spam() -> void:
	_spam_count       = 0
	_spam_decay_timer = 0.0

func _resolve(result: Result, combat_data: CombatData) -> void:
	_is_active = false
	_timer     = 0.0
	
	match result:
		Result.WHIFF:
			_spam_count = mini(_spam_count + 1, 3)
			_start_cooldown()
		Result.PERFECT:
			reset_spam()
		Result.GUARD:
			pass
	resolved.emit(result, combat_data)

func _start_cooldown() -> void:
	_in_cooldown  = true
	await get_tree().create_timer(whiff_cooldown, true, false, true).timeout
	_in_cooldown = false
