class_name ParryResolver extends Node


enum Result {
	NONE,
	DEFLECT,
}

@export var tuning: CombatTuning

var _is_action_active: bool  = false   # běží parry akce (od stisku)
var _action_timer: float     = 0.0     # čas od stisku
var _locked_window: float    = 0.0     # délka okna zamčená v momentě stisku
var _window_resolved: bool   = false   # okno už skončilo (zásahem nebo vypršením)
var _spam_count: int         = 0
var _spam_decay_timer: float = 0.0


func _ready() -> void:
	if tuning == null:
		tuning = CombatTuning.new()


func try_start_deflect() -> void:
	_is_action_active = true
	_action_timer     = 0.0
	_window_resolved  = false
	_locked_window    = get_current_deflect_window()


func stop_deflect() -> void:
	_is_action_active = false
	_action_timer     = 0.0


func tick(delta: float) -> void:
	if not _is_action_active:
		if _spam_count > 0:
			_spam_decay_timer += delta
			if _spam_decay_timer >= tuning.parry_spam_decay_time:
				_spam_count       = 0
				_spam_decay_timer = 0.0
		return

	_action_timer += delta
	if not _window_resolved and _action_timer >= _locked_window:
		# okno vypršelo bez zásahu = whiff
		_window_resolved  = true
		_spam_count       = mini(_spam_count + 1, tuning.parry_spam_max_count)
		_spam_decay_timer = 0.0   # decay se počítá od POSLEDNÍHO whiffu


func get_current_deflect_window() -> float:
	match _spam_count:
		0, 1: return tuning.deflect_window
		2:    return tuning.deflect_window * 0.6
		_:    return tuning.deflect_window * 0.3


func evaluate(combat_data: CombatData) -> Result:
	if not _is_action_active:
		return Result.NONE
	if combat_data and combat_data.is_unblockable:
		return Result.NONE
	if _window_resolved or _action_timer >= _locked_window:
		return Result.NONE

	_window_resolved  = true
	_spam_count       = 0
	_spam_decay_timer = 0.0
	return Result.DEFLECT


func is_deflect_active() -> bool:
	return _is_action_active and not _window_resolved and _action_timer < _locked_window


func get_spam_count() -> int:
	return _spam_count
